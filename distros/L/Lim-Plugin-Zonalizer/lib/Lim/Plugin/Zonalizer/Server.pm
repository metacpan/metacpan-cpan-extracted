package Lim::Plugin::Zonalizer::Server;

use common::sense;

use Carp;
use Scalar::Util qw(weaken blessed);

use Lim::Plugin::Zonalizer qw(:err :status);

use Lim              ();
use Lim::Error       ();
use Data::UUID       ();
use MIME::Base64     ();
use AnyEvent         ();
use AnyEvent::Handle ();
use JSON::XS         ();
use HTTP::Status     ();
use URI::Escape::XS qw(uri_escape);
use AnyEvent::Util ();

use Zonemaster                ();
use Zonemaster::Translator    ();
use Zonemaster::Logger::Entry ();
use POSIX qw(setlocale LC_MESSAGES);

use base qw(Lim::Component::Server);

=encoding utf8

=head1 NAME

Lim::Plugin::Zonalizer::Server - Server class for the zonalizer Lim plugin

=head1 VERSION

See L<Lim::Plugin::Zonalizer> for version.

=cut

our $VERSION = $Lim::Plugin::Zonalizer::VERSION;

our %STAT = (
    api => {
        requests => 0,
        errors   => 0
    },
    analysis => {
        ongoing   => 0,
        completed => 0,
        failed    => 0
    }
);

our %TEST;
our %TEST_DB;
our %TEST_SPACE;

our $TRANSLATOR;

=head1 SYNOPSIS

  use Lim::Plugin::Zonalizer;

  # Create a Server object
  $server = Lim::Plugin::Zonalizer->Server;

=head1 METHODS

These methods are called from the Lim framework and should not be used else
where.

Please see L<Lim::Plugin::Zonalizer> for full documentation of calls.

=over 4

=item Init

=cut

sub Init {
    my ( $self ) = @_;
    my $real_self = $self;
    weaken( $self );

    #
    # Default configuration
    #

    $self->{default_limit} = 10;
    $self->{max_limit}     = 10;
    $self->{base_url}      = 1;
    $self->{db_driver}     = 'Memory';
    $self->{db_conf}       = {};
    $self->{lang}          = $ENV{LC_MESSAGES} || $ENV{LC_ALL} || $ENV{LANG} || $ENV{LANGUAGE} || 'en_US';
    $self->{test_ipv4}     = 1;
    $self->{test_ipv6}     = 1;
    $self->{allow_ipv4}    = 1;
    $self->{allow_ipv6}    = 1;
    $self->{max_ongoing}   = 5;
    $self->{collector}     = {
        exec    => '/usr/bin/zonalizer-collector',
        threads => 5
    };
    $self->{collector_policy}         = {};
    $self->{allow_undelegated}        = 1;
    $self->{force_undelegated}        = 0;
    $self->{max_undelegated_ns}       = 10;
    $self->{max_undelegated_ds}       = 10;
    $self->{allow_meta_data}          = 0;
    $self->{max_meta_data_entries}    = 42;
    $self->{max_meta_data_entry_size} = 512;

    #
    # Load configuration
    #

    if ( ref( Lim->Config->{zonalizer} ) eq 'HASH' ) {
        foreach (
            qw(default_limit max_limit base_url db_driver custom_base_url
            lang test_ipv4 test_ipv6 allow_ipv4 allow_ipv6 max_ongoing
            allow_undelegated force_undelegated max_undelegated_ns
            max_undelegated_ds allow_meta_data max_meta_data_entries
            max_meta_data_entry_size)
          )
        {
            if ( defined Lim->Config->{zonalizer}->{$_} ) {
                $self->{$_} = Lim->Config->{zonalizer}->{$_};
            }
        }

        if ( defined Lim->Config->{zonalizer}->{db_conf} ) {
            unless ( ref( Lim->Config->{zonalizer}->{db_conf} ) eq 'HASH' ) {
                confess 'Configuration for db_conf is wrong, must be HASH';
            }

            $self->{db_conf} = Lim->Config->{zonalizer}->{db_conf};
        }

        if ( defined Lim->Config->{zonalizer}->{collector} ) {
            unless ( ref( Lim->Config->{zonalizer}->{collector} ) eq 'HASH' ) {
                confess 'Configuration for collector is wrong, must be HASH';
            }

            foreach ( qw(exec config policy sourceaddr threads) ) {
                if ( defined Lim->Config->{zonalizer}->{collector}->{$_} ) {
                    $self->{collector}->{$_} = Lim->Config->{zonalizer}->{collector}->{$_};
                }
            }

            if ( defined Lim->Config->{zonalizer}->{collector}->{policies} ) {
                unless ( ref( Lim->Config->{zonalizer}->{collector}->{policies} ) eq 'ARRAY' ) {
                    confess 'Configuration for collector->policies is wrong, must be ARRAY';
                }

                my $count = 1;
                foreach my $policy ( @{ Lim->Config->{zonalizer}->{collector}->{policies} } ) {
                    unless ( ref( $policy ) eq 'HASH' ) {
                        confess 'Configuration for collector->policies[' . $count . '] is wrong, must be HASH';
                    }

                    foreach ( qw(name display policy) ) {
                        unless ( defined $policy->{$_} ) {
                            confess 'Configuration for collector->policies[' . $count . ']->' . $_ . ' is wrong, must be defined';
                        }
                    }

                    foreach ( qw(description exec config sourceaddr threads) ) {
                        if ( exists $policy->{$_} and !defined $policy->{$_} ) {
                            confess 'Configuration for collector->policies[' . $count . ']->' . $_ . ' is wrong, must be defined';
                        }
                        if ( !exists $policy->{$_} and exists $self->{collector}->{$_} ) {
                            $policy->{$_} = $self->{collector}->{$_};
                        }
                    }

                    unless ( $policy->{name} =~ /^[\w-]+/o ) {
                        confess 'Configuration for collector->policies[' . $count . '] is wrong, illegal characters in policy name';
                    }
                    if ( exists $self->{collector_policy}->{ $policy->{name} } ) {
                        confess 'Configuration for collector->policies[' . $count . '] is wrong, policy ' . $policy->{name} . ' already exists';
                    }
                    if ( $policy->{exec} and !-x $policy->{exec} ) {
                        confess 'Configuration for collector->policies[' . $count . '] is wrong, ' . $policy->{exec} . ' is not an executable';
                    }

                    $self->{collector_policy}->{ $policy->{name} } = $policy;
                    $count++;
                }
            }
        }
    }

    if ( exists $self->{custom_base_url} ) {
        $self->{custom_base_url} =~ s/[\/\s]+$//o;
    }

    unless ( $self->{allow_ipv4} ) {
        $self->{test_ipv4} = 0;
    }
    unless ( $self->{allow_ipv6} ) {
        $self->{test_ipv6} = 0;
    }
    unless ( $self->{allow_ipv4} || $self->{allow_ipv6} ) {
        confess 'Configuration error: Must have atleast one of allow_ipv4 or allow_ipv6 set';
    }
    unless ( $self->{test_ipv4} || $self->{test_ipv6} ) {
        confess 'Configuration error: Must have atleast one of test_ipv4 or test_ipv6 set';
    }
    unless ( $self->{max_ongoing} > 0 ) {
        confess 'Configuration error: max_ongoing must be 1 or greater';
    }
    unless ( -x $self->{collector}->{exec} ) {
        confess 'Configuration error: collector->exec ' . $self->{collector}->{exec} . ' is not an executable';
    }
    unless ( $self->{collector}->{threads} > 0 ) {
        confess 'Configuration error: collector->threads must be 1 or greater';
    }
    if ( !$self->{allow_undelegated} and $self->{force_undelegated} ) {
        confess 'Configuration error: allow_undelegated can not be false when force_undelegated is true';
    }
    if ( $self->{allow_undelegated} ) {
        unless ( $self->{max_undelegated_ns} > 0 ) {
            confess 'Configuration error: max_undelegated_ns must be 1 or greater';
        }
        unless ( $self->{max_undelegated_ds} > 0 ) {
            confess 'Configuration error: max_undelegated_ds must be 1 or greater';
        }
    }
    if ( $self->{allow_meta_data} ) {
        unless ( $self->{max_meta_data_entries} > 0 ) {
            confess 'Configuration error: max_meta_data_entries must be 1 or greater';
        }
        unless ( $self->{max_meta_data_entry_size} > 0 ) {
            confess 'Configuration error: max_meta_data_entry_size must be 1 or greater';
        }
    }

    #
    # Load database
    #

    my $db_driver = 'Lim::Plugin::Zonalizer::DB::' . $self->{db_driver};
    eval 'use ' . $db_driver . ';';
    if ( $@ ) {
        confess $@;
    }
    $self->{db} = $db_driver->new( %{ $self->{db_conf} } );

    #
    # Build translator
    #

    $self->{lang} =~ s/\..*$//o;

    unless ( $self->{lang} =~ /^[a-z]{2}_[A-Z]{2}$/o ) {
        confess 'Invalid language set for translations';
    }

    $TRANSLATOR = Zonemaster::Translator->new;
    $TRANSLATOR->data;

    unless ( setlocale( LC_MESSAGES, $self->{lang} . '.UTF-8' ) ) {
        confess 'Unsupported locale, setlocale( ' . $self->{lang} . '.UTF-8 ) failed: ' . $!;
    }

    #
    # Temporary memory scrubber
    #

    $self->{cleaner} = AnyEvent->timer(
        after    => 60,
        interval => 60,
        cb       => sub {
            unless ( $self ) {
                return;
            }

            foreach ( values %TEST ) {
                if ( $_->{updated} < ( time - 600 ) ) {
                    delete $TEST{ $_->{id} };
                    delete $TEST_DB{ $_->{id} };
                    delete $TEST_SPACE{ $_->{id} };
                }
            }
        }
    );

    #
    # Start collector
    #

    my $code;
    $code = sub {
        unless ( defined $self ) {
            return;
        }

        Lim::DEBUG and $self->{logger}->debug( '(re)starting default collector' );

        $self->{collector}->{analyze} = $self->StartCollector(
            exec => $self->{collector}->{exec},
            $self->{collector}->{config}     ? ( config     => $self->{collector}->{config} )     : (),
            $self->{collector}->{policy}     ? ( policy     => $self->{collector}->{policy} )     : (),
            $self->{collector}->{sourceaddr} ? ( sourceaddr => $self->{collector}->{sourceaddr} ) : (),
            $self->{collector}->{threads}    ? ( threads    => $self->{collector}->{threads} )    : (),
            on_eof => $code
        );
    };
    $code->();

    foreach ( values %{ $self->{collector_policy} } ) {
        my $policy = $_;
        my $code;
        $code = sub {
            unless ( defined $self ) {
                return;
            }

            Lim::DEBUG and $self->{logger}->debug( '(re)starting collector for policy ', $policy->{name} );

            $self->{collector_policy}->{ $policy->{name} }->{analyze} = $self->StartCollector(
                exec => $policy->{exec},
                $policy->{config}     ? ( config     => $policy->{config} )     : (),
                $policy->{policy}     ? ( policy     => $policy->{policy} )     : (),
                $policy->{sourceaddr} ? ( sourceaddr => $policy->{sourceaddr} ) : (),
                $policy->{threads}    ? ( threads    => $policy->{threads} )    : (),
                on_eof => $code
            );
        };
        $code->();
    }
}

=item Read1

=cut

sub Read1 {
    my ( $self, $cb ) = @_;
    $STAT{api}->{requests}++;

    #
    # This call is only used to map to other calls and should not be called
    # directly so return an error if anyone does.
    #

    $STAT{api}->{errors}++;
    $self->Error(
        $cb,
        Lim::Error->new(
            module => $self,
            code   => HTTP::Status::HTTP_BAD_REQUEST
        )
    );
    return;
}

=item Create1

=cut

sub Create1 {
    my ( $self, $cb ) = @_;
    $STAT{api}->{requests}++;

    #
    # This call is only used to map to other calls and should not be called
    # directly so return an error if anyone does.
    #

    $STAT{api}->{errors}++;
    $self->Error(
        $cb,
        Lim::Error->new(
            module => $self,
            code   => HTTP::Status::HTTP_BAD_REQUEST
        )
    );
    return;
}

=item Update1

=cut

sub Update1 {
    my ( $self, $cb ) = @_;
    $STAT{api}->{requests}++;

    #
    # This call is only used to map to other calls and should not be called
    # directly so return an error if anyone does.
    #

    $STAT{api}->{errors}++;
    $self->Error(
        $cb,
        Lim::Error->new(
            module => $self,
            code   => HTTP::Status::HTTP_BAD_REQUEST
        )
    );
    return;
}

=item Delete1

=cut

sub Delete1 {
    my ( $self, $cb ) = @_;
    $STAT{api}->{requests}++;

    #
    # This call is only used to map to other calls and should not be called
    # directly so return an error if anyone does.
    #

    $STAT{api}->{errors}++;
    $self->Error(
        $cb,
        Lim::Error->new(
            module => $self,
            code   => HTTP::Status::HTTP_BAD_REQUEST
        )
    );
    return;
}

=item ReadVersion

=cut

sub ReadVersion {
    my ( $self, $cb, $q ) = @_;
    $STAT{api}->{requests}++;

    unless ( $q->{version} == 1 ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_INVALID_API_VERSION
            )
        );
        return;
    }

    my @tests = (
        {
            name    => 'Basic',
            version => Zonemaster::Test::Basic->VERSION
        }
    );

    foreach ( Zonemaster::Test->modules ) {
        push(
            @tests,
            {
                name    => $_,
                version => ( 'Zonemaster::Test::' . $_ )->VERSION
            }
        );
    }

    $self->Successful(
        $cb,
        {
            version    => $VERSION,
            zonemaster => {
                version => Zonemaster->VERSION,
                tests   => \@tests
            }
        }
    );
    return;
}

=item ReadStatus

=cut

sub ReadStatus {
    my ( $self, $cb, $q ) = @_;
    $STAT{api}->{requests}++;

    unless ( $q->{version} == 1 ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_INVALID_API_VERSION
            )
        );
        return;
    }

    $self->Successful( $cb, \%STAT );
    return;
}

=item ReadAnalysis

=cut

sub ReadAnalysis {
    my ( $self, $cb, $q ) = @_;
    my $real_self = $self;
    weaken( $self );
    $STAT{api}->{requests}++;

    unless ( $q->{version} == 1 ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_INVALID_API_VERSION
            )
        );
        return;
    }

    if ( exists $q->{search} and ( !defined $q->{search} || $q->{search} !~ /^(?:(?:[a-zA-Z0-9-]+\.)*(?:[a-zA-Z0-9-]+\.?|\.)|\.(?:[a-zA-Z0-9-]+\.)*(?:[a-zA-Z0-9-]+\.?))$/o ) ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_INVALID_FQDN
            )
        );
        return;
    }

    #
    # Verify limit and set base url if configured/requested.
    #

    my $limit = $q->{limit} > 0 ? $q->{limit} : $self->{default_limit};
    if ( $limit > $self->{max_limit} ) {
        $limit = $self->{max_limit};
    }
    my $base_url = '';
    if ( exists $self->{custom_base_url} ) {
        $base_url = $self->{custom_base_url};
    }
    elsif ( ( defined $q->{base_url} ? $q->{base_url} : $self->{base_url} ) and $cb->request ) {
        $base_url = $cb->request->header( 'X-Lim-Base-URL' );
    }

    #
    # Get translator
    #

    my ( $translator, $lang, $error ) = $self->GetTranslator( $q->{lang} );

    unless ( $translator and $lang ) {
        $self->Error(
            $cb,
            $error ? $error : Lim::Error->new(
                module => $self,
                code   => HTTP::Status::HTTP_INTERNAL_SERVER_ERROR
            )
        );
        return;
    }

    #
    # Returned in memory ongoing analysis if requested.
    #

    if ( defined $q->{ongoing} && $q->{ongoing} == 1 ) {
        my @analysis;

        foreach ( sort { $b->{update} <=> $a->{update} } values %TEST ) {
            if ( $q->{space} ) {
                unless ( exists $TEST_SPACE{ $_->{id} }
                    and $TEST_SPACE{ $_->{id} } eq $q->{space} )
                {
                    next;
                }
            }
            else {
                if ( exists $TEST_SPACE{ $_->{id} } ) {
                    next;
                }
            }

            my %test = %{$_};

            unless ( $q->{results} ) {
                delete $test{results};
            }
            else {
                my @results;

                setlocale( LC_MESSAGES, $lang . '.UTF-8' );
                foreach my $result ( @{ $test{results} } ) {
                    my $entry = Zonemaster::Logger::Entry->new( $result );

                    my $message = $translator->translate_tag( $entry );
                    utf8::decode( $message );

                    push(
                        @results,
                        {
                            %$result,
                            message => $message
                        }
                    );
                }
                setlocale( LC_MESSAGES, $self->{lang} . '.UTF-8' );

                $test{results} = \@results;
            }
            $test{url} = $base_url . '/zonalizer/' . uri_escape( $q->{version} ) . '/analysis/' . uri_escape( $test{id} );
            if ( $q->{space} ) {
                $test{url} .= '?space' . uri_escape( $q->{space} );
            }

            push( @analysis, \%test );

            if ( scalar @analysis == $limit ) {
                last;
            }
        }

        $self->Successful( $cb, { analysis => \@analysis } );
        return;
    }

    #
    # Query database for analysis.
    #

    $self->{db}->ReadAnalysis(
        %$q,
        limit => $limit,
        cb    => sub {
            my $paging = shift;
            my @analysis;

            # uncoverable branch true
            unless ( defined $self ) {

                # uncoverable statement
                return;
            }

            if ( $@ ) {
                $STAT{api}->{errors}++;

                if ( $@ eq ERR_INVALID_LIMIT or $@ eq ERR_INVALID_SORT_FIELD ) {
                    $self->Error(
                        $cb,
                        Lim::Error->new(
                            module  => $self,
                            code    => HTTP::Status::HTTP_BAD_REQUEST,
                            message => $@
                        )
                    );
                    return;
                }

                # uncoverable branch false
                Lim::ERR and $self->{logger}->error( $@ );
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module => $self,
                        code   => HTTP::Status::HTTP_INTERNAL_SERVER_ERROR
                    )
                );
                return;
            }

            #
            # Construct the result
            #

            if ( defined $q->{results} and $q->{results} == 1 ) {
                setlocale( LC_MESSAGES, $lang . '.UTF-8' );
                foreach ( @_ ) {
                    unless ( ref( $_->{results} ) eq 'ARRAY' ) {
                        next;
                    }

                    foreach my $result ( @{ $_->{results} } ) {
                        my $entry = Zonemaster::Logger::Entry->new( $result );
                        $result->{message} = $translator->translate_tag( $entry );
                        utf8::decode( $result->{message} );
                    }
                }
                setlocale( LC_MESSAGES, $self->{lang} . '.UTF-8' );
            }
            foreach ( @_ ) {
                my ( @ns, @ds, @meta_data );

                if ( $_->{ns} ) {
                    foreach my $ns ( @{ $_->{ns} } ) {
                        push(
                            @ns,
                            {
                                fqdn => $ns->{fqdn},
                                exists $ns->{ip} ? ( ip => $ns->{ip} ) : ()
                            }
                        );
                    }
                }

                if ( $_->{ds} ) {
                    foreach my $ds ( @{ $_->{ds} } ) {
                        push(
                            @ds,
                            {
                                keytag    => $ds->{keytag},
                                algorithm => $ds->{algorithm},
                                type      => $ds->{type},
                                digest    => $ds->{digest}
                            }
                        );
                    }
                }

                if ( $_->{meta_data} ) {
                    foreach my $meta_data ( @{ $_->{meta_data} } ) {
                        push(
                            @meta_data,
                            {
                                key   => $meta_data->{key},
                                value => $meta_data->{value}
                            }
                        );
                    }
                }

                push(
                    @analysis,
                    {
                        id   => $_->{id},
                        fqdn => $_->{fqdn},
                        exists $_->{policy}
                        ? (
                            policy => {
                                name    => $_->{policy}->{name},
                                display => $_->{policy}->{display},
                                $_->{policy}->{description} ? ( description => $_->{policy}->{description} ) : ()
                            }
                          )
                        : (),
                        url => $base_url . '/zonalizer/' . uri_escape( $q->{version} ) . '/analysis/' . uri_escape( $_->{id} ) . ( $q->{space} ? '?space=' . uri_escape( $q->{space} ) : '' ),
                        status   => $_->{status},
                        progress => $_->{progress},
                        created  => $_->{created},
                        updated  => $_->{updated},
                        exists $_->{error} ? ( error => $_->{error} ) : (),
                        defined $q->{results} && $q->{results} == 1 && exists $_->{results} ? ( results => $_->{results} ) : (),
                        summary => {
                            notice   => $_->{summary}->{notice},
                            warning  => $_->{summary}->{warning},
                            error    => $_->{summary}->{error},
                            critical => $_->{summary}->{critical}
                        },
                        ipv4 => $_->{ipv4},
                        ipv6 => $_->{ipv6},
                        scalar @ns        ? ( ns        => \@ns )        : (),
                        scalar @ds        ? ( ds        => \@ds )        : (),
                        scalar @meta_data ? ( meta_data => \@meta_data ) : ()
                    }
                );
            }

            $self->Successful(
                $cb,
                {
                    analysis => \@analysis,
                    defined $paging
                    ? (
                        paging => {
                            cursors => {
                                after  => $paging->{after},
                                before => $paging->{before}
                            },
                            $paging->{previous} ? ( previous => $base_url . '/zonalizer/' . uri_escape( $q->{version} ) . '/analysis?limit=' . uri_escape( $limit ) . '&before=' . uri_escape( $paging->{before} ) . ( defined $q->{sort} ? '&sort=' . uri_escape( $q->{sort} ) : '' ) . ( defined $q->{direction} ? '&direction=' . uri_escape( $q->{direction} ) : '' ) . ( defined $paging->{extra} ? '&' . $paging->{extra} : '' ) ) : (),
                            $paging->{next}     ? ( next     => $base_url . '/zonalizer/' . uri_escape( $q->{version} ) . '/analysis?limit=' . uri_escape( $limit ) . '&after=' . uri_escape( $paging->{after} ) .   ( defined $q->{sort} ? '&sort=' . uri_escape( $q->{sort} ) : '' ) . ( defined $q->{direction} ? '&direction=' . uri_escape( $q->{direction} ) : '' ) . ( defined $paging->{extra} ? '&' . $paging->{extra} : '' ) ) : ()
                        }
                      )
                    : ()
                }
            );
        }
    );
    return;
}

=item DeleteAnalysis

=cut

sub DeleteAnalysis {
    my ( $self, $cb, $q ) = @_;
    my $real_self = $self;
    weaken( $self );
    $STAT{api}->{requests}++;

    unless ( $q->{version} == 1 ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_INVALID_API_VERSION
            )
        );
        return;
    }

    $self->{db}->DeleteAnalysis(
        $q->{space} ? ( space => $q->{space} ) : (),
        cb => sub {
            my ( $deleted_analysis ) = @_;

            # uncoverable branch true
            unless ( defined $self ) {

                # uncoverable statement
                return;
            }

            if ( $@ ) {
                $STAT{api}->{errors}++;

                # uncoverable branch false
                Lim::ERR and $self->{logger}->error( $@ );
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module => $self,
                        code   => HTTP::Status::HTTP_INTERNAL_SERVER_ERROR
                    )
                );
                return;
            }

            if ( $q->{space} ) {
                foreach ( keys %TEST_SPACE ) {
                    if ( $TEST_SPACE{$_} eq $q->{space} ) {
                        delete $TEST{$_};
                        delete $TEST_DB{$_};
                        delete $TEST_SPACE{$_};
                    }
                }
            }
            else {
                %TEST       = ();
                %TEST_DB    = ();
                %TEST_SPACE = ();
            }

            $self->Successful( $cb );
        }
    );
    return;
}

=item CreateAnalyze

=cut

sub CreateAnalyze {
    my ( $self, $cb, $q ) = @_;
    my $real_self = $self;
    weaken( $self );
    $STAT{api}->{requests}++;

    unless ( $q->{version} == 1 ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_INVALID_API_VERSION
            )
        );
        return;
    }

    if ( $STAT{analysis}->{ongoing} >= $self->{max_ongoing} ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_SERVICE_UNAVAILABLE,
                message => ERR_QUEUE_FULL
            )
        );
        return;
    }
    unless ( $q->{fqdn} =~ /^(?:[a-zA-Z0-9-]+\.)*(?:[a-zA-Z0-9-]+\.?|\.)$/o ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_INVALID_FQDN
            )
        );
        return;
    }

    my $policy;
    if ( $q->{policy} ) {
        unless ( exists $self->{collector_policy}->{ $q->{policy} } ) {
            $STAT{api}->{errors}++;
            $self->Error(
                $cb,
                Lim::Error->new(
                    module  => $self,
                    code    => HTTP::Status::HTTP_BAD_REQUEST,
                    message => ERR_POLICY_NOT_FOUND
                )
            );
            return;
        }

        $policy = {
            name    => $self->{collector_policy}->{ $q->{policy} }->{name},
            display => $self->{collector_policy}->{ $q->{policy} }->{display},
            $self->{collector_policy}->{ $q->{policy} }->{description} ? ( description => $self->{collector_policy}->{ $q->{policy} }->{description} ) : ()
        };
    }

    my ( $ipv4, $ipv6 ) = ( 0, 0 );

    if ( exists $q->{ipv4} ) {
        if ( $q->{ipv4} ) {
            unless ( $self->{allow_ipv4} ) {
                $STAT{api}->{errors}++;
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module  => $self,
                        code    => HTTP::Status::HTTP_BAD_REQUEST,
                        message => ERR_IPV4_NOT_ALLOWED
                    )
                );
                return;
            }

            $ipv4 = 1;
        }
    }
    else {
        $ipv4 = $self->{test_ipv4};
    }

    if ( exists $q->{ipv6} ) {
        if ( $q->{ipv6} ) {
            unless ( $self->{allow_ipv6} ) {
                $STAT{api}->{errors}++;
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module  => $self,
                        code    => HTTP::Status::HTTP_BAD_REQUEST,
                        message => ERR_IPV6_NOT_ALLOWED
                    )
                );
                return;
            }

            $ipv6 = 1;
        }
    }
    else {
        $ipv6 = $self->{test_ipv6};
    }

    unless ( $ipv4 || $ipv6 ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_NO_IP_PROTOCOL
            )
        );
        return;
    }

    my @ns;
    if ( $q->{ns} ) {
        unless ( ref( $q->{ns} ) eq 'ARRAY' ) {
            $q->{ns} = [ $q->{ns} ];
        }

        foreach ( @{ $q->{ns} } ) {
            if ( !$_->{fqdn} or ( exists $_->{ip} && !$_->{ip} ) ) {
                $STAT{api}->{errors}++;
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module  => $self,
                        code    => HTTP::Status::HTTP_BAD_REQUEST,
                        message => ERR_INVALID_NS
                    )
                );
                return;
            }

            push( @ns, join( '', '--ns=', $_->{fqdn}, $_->{ip} ? ( '/', $_->{ip} ) : () ) );
        }
    }

    my @ds;
    if ( $q->{ds} ) {
        unless ( ref( $q->{ds} ) eq 'ARRAY' ) {
            $q->{ds} = [ $q->{ds} ];
        }

        foreach ( @{ $q->{ds} } ) {
            unless ( $_->{keytag} and $_->{algorithm} and $_->{type} and $_->{digest} ) {
                $STAT{api}->{errors}++;
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module  => $self,
                        code    => HTTP::Status::HTTP_BAD_REQUEST,
                        message => ERR_INVALID_DS
                    )
                );
                return;
            }

            push( @ds, join( '--ds=', join( ',', $_->{keytag}, $_->{algorithm}, $_->{type}, $_->{digest} ) ) );
        }
    }

    if ( !$self->{allow_undelegated} and ( scalar @ns or scalar @ds ) ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_UNDELEGATED_NOT_ALLOWED
            )
        );
        return;
    }

    if ( $self->{force_undelegated} and !scalar @ns ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_UNDELEGATED_FORCED
            )
        );
        return;
    }

    if ( scalar @ns > $self->{max_undelegated_ns} ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_INVALID_NS
            )
        );
        return;
    }

    if ( scalar @ds > $self->{max_undelegated_ds} ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_INVALID_DS
            )
        );
        return;
    }

    if ( $q->{meta_data} ) {
        unless ( $self->{allow_meta_data} ) {
            $STAT{api}->{errors}++;
            $self->Error(
                $cb,
                Lim::Error->new(
                    module  => $self,
                    code    => HTTP::Status::HTTP_BAD_REQUEST,
                    message => ERR_META_DATA_NOT_ALLOWED
                )
            );
            return;
        }

        unless ( ref( $q->{meta_data} ) eq 'ARRAY' ) {
            $q->{meta_data} = [ $q->{meta_data} ];
        }

        my $count = 0;
        foreach ( @{ $q->{meta_data} } ) {
            unless ($count < $self->{max_meta_data_entries}
                and $_->{key}
                and $_->{value}
                and ( length( $_->{key} ) + length( $_->{value} ) ) <= $self->{max_meta_data_entry_size} )
            {
                $STAT{api}->{errors}++;
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module  => $self,
                        code    => HTTP::Status::HTTP_BAD_REQUEST,
                        message => ERR_INVALID_META_DATA
                    )
                );
                return;
            }

            $count++;
        }
    }

    my $collector_analyze = $self->{collector}->{analyze};
    if ( $q->{policy} ) {
        $collector_analyze = $self->{collector_policy}->{ $q->{policy} }->{analyze};
    }
    unless ( ref( $collector_analyze ) eq 'CODE' ) {
        Lim::ERR and $self->{logger}->error( 'Unable to call collector' );
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module => $self,
                code   => HTTP::Status::HTTP_INTERNAL_SERVER_ERROR
            )
        );
        return;
    }

    my $fqdn = $q->{fqdn};
    $fqdn =~ s/\.$//o;
    $fqdn .= '.';

    my $id = MIME::Base64::encode_base64url( Data::UUID->new->create );

    if ( exists $TEST{$id} ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_CONFLICT,
                message => ERR_INTERNAL_DATABASE
            )
        );
        return;
    }

    my $test = $TEST{$id} = {
        id   => $id,
        fqdn => $fqdn,
        $policy ? ( policy => $policy ) : (),
        status   => STATUS_RESERVED,
        progress => 0,
        created  => time,
        updated  => time,
        summary  => {
            notice   => 0,
            warning  => 0,
            error    => 0,
            critical => 0
        },
        ipv4 => $ipv4,
        ipv6 => $ipv6,
        $q->{ns}        ? ( ns        => $q->{ns} )        : (),
        $q->{ds}        ? ( ds        => $q->{ds} )        : (),
        $q->{meta_data} ? ( meta_data => $q->{meta_data} ) : ()
    };
    if ( $q->{space} ) {
        $TEST_SPACE{$id} = $q->{space};
    }

    $STAT{analysis}->{ongoing}++;

    $self->{logger}->debug( 'Reserving ', $fqdn, ' ', $id );

    $self->{db}->CreateAnalyze(
        $q->{space} ? ( space => $q->{space} ) : (),
        analyze => $test,
        cb      => sub {
            my ( $object ) = @_;

            # uncoverable branch true
            unless ( defined $self ) {

                # uncoverable statement
                return;
            }

            if ( $@ ) {
                $self->{logger}->error( 'Unable to store ', $id, ' in database: ', $@ );

                $STAT{analysis}->{ongoing}--;
                $STAT{analysis}->{failed}++;

                delete $TEST{$id};
                delete $TEST_SPACE{$id};

                $STAT{api}->{errors}++;
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module  => $self,
                        code    => HTTP::Status::HTTP_CONFLICT,
                        message => ERR_INTERNAL_DATABASE
                    )
                );
                return;
            }

            $TEST_DB{$id} = $object;

            $test->{status} = STATUS_QUEUED;

            $self->{logger}->debug( 'Analyzing ', $fqdn, ' ', $id, ( $q->{policy} ? ' ' . $q->{policy} : '' ) );

            my $modules      = 0;
            my $modules_done = 0;
            my $started      = 0;
            my $result_id    = 0;
            my $failed       = sub {
                $STAT{analysis}->{ongoing}--;
                $STAT{analysis}->{failed}++;
                $test->{status} = STATUS_FAILED;
            };
            my $store = sub {
                $self->StoreAnalyze( $id );
            };

            $collector_analyze->(
                sub {
                    my ( $msg ) = @_;

                    unless ( $msg ) {
                        $test->{progress} = 100;
                        delete $test->{results};
                        if ( defined $failed ) {
                            $failed->();
                            undef $failed;
                        }
                        if ( defined $store ) {
                            $store->();
                            undef $store;
                        }
                        return 1;
                    }

                    $test->{updated} = time;
                    $test->{status}  = STATUS_ANALYZING;

                    if ( $msg->{level} eq 'DEBUG' || ( $msg->{level} eq 'INFO' && $msg->{tag} eq 'POLICY_DISABLED' ) ) {
                        if ( !$started && $msg->{tag} eq 'MODULE_VERSION' ) {
                            $modules++;
                        }
                        elsif ( $_->{tag} eq 'MODULE_END' and $_->{args}->{module} eq 'Lim::Plugin::Zonalizer::Collector' ) {
                            $test->{progress} = 100;
                            if ( defined $failed ) {
                                $STAT{analysis}->{ongoing}--;
                                $STAT{analysis}->{completed}++;
                                $test->{status} = exists $test->{results} ? STATUS_DONE : STATUS_UNKNOWN;
                                undef $failed;
                            }
                            if ( defined $store ) {
                                $store->();
                                undef $store;
                            }
                            return 1;
                        }
                        elsif ( $msg->{tag} eq 'MODULE_END' || $msg->{tag} eq 'POLICY_DISABLED' ) {
                            $started = 1;
                            $modules_done++;

                            $test->{progress} = ( $modules_done * 100 ) / $modules;

                            $self->{logger}->debug( 'done ', $modules_done, ' progress ', $test->{progress} );
                        }
                        else {
                            $started = 1;
                        }
                    }

                    if ( $msg->{level} eq 'DEBUG' ) {
                        next;
                    }

                    if ( $msg->{level} eq 'NOTICE' ) {
                        $test->{summary}->{notice}++;
                    }
                    elsif ( $msg->{level} eq 'WARNING' ) {
                        $test->{summary}->{warning}++;
                    }
                    elsif ( $msg->{level} eq 'ERROR' ) {
                        $test->{summary}->{error}++;
                    }
                    elsif ( $msg->{level} eq 'CRITICAL' ) {
                        $test->{summary}->{critical}++;
                    }

                    $msg->{_id} = $result_id++;
                    push( @{ $test->{results} }, $msg );

                    return;
                },
                id   => $id,
                fqdn => $fqdn,
                ipv4 => $ipv4,
                ipv6 => $ipv6,
                $q->{ns} ? ( ns => $q->{ns} ) : (),
                $q->{ds} ? ( ds => $q->{ds} ) : ()
            );

            $self->Successful( $cb, { id => $id } );
            return;
        }
    );
    return;
}

=item ReadAnalyze

=cut

sub ReadAnalyze {
    my ( $self, $cb, $q ) = @_;
    my $real_self = $self;
    weaken( $self );
    $STAT{api}->{requests}++;

    unless ( $q->{version} == 1 ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_INVALID_API_VERSION
            )
        );
        return;
    }

    #
    # Set base url if configured/requested.
    #

    my $base_url = '';
    if ( exists $self->{custom_base_url} ) {
        $base_url = $self->{custom_base_url};
    }
    elsif ( ( defined $q->{base_url} ? $q->{base_url} : $self->{base_url} ) and $cb->request ) {
        $base_url = $cb->request->header( 'X-Lim-Base-URL' );
    }

    #
    # Get translator
    #

    my ( $translator, $lang, $error ) = $self->GetTranslator( $q->{lang} );

    unless ( $translator and $lang ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            $error ? $error : Lim::Error->new(
                module => $self,
                code   => HTTP::Status::HTTP_INTERNAL_SERVER_ERROR
            )
        );
        return;
    }

    #
    # Check for analyze in memory.
    #

    if ( exists $TEST{ $q->{id} } ) {
        if ( $q->{space} ) {
            unless ( exists $TEST_SPACE{ $q->{id} }
                and $TEST_SPACE{ $q->{id} } eq $q->{space} )
            {
                $STAT{api}->{errors}++;
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module  => $self,
                        code    => HTTP::Status::HTTP_NOT_FOUND,
                        message => ERR_ID_NOT_FOUND
                    )
                );
                return;
            }
        }
        else {
            if ( exists $TEST_SPACE{ $q->{id} } ) {
                $STAT{api}->{errors}++;
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module  => $self,
                        code    => HTTP::Status::HTTP_NOT_FOUND,
                        message => ERR_ID_NOT_FOUND
                    )
                );
                return;
            }
        }

        my %test = %{ $TEST{ $q->{id} } };
        $test{url} = $base_url . '/zonalizer/' . uri_escape( $q->{version} ) . '/analysis/' . uri_escape( $test{id} );
        if ( $q->{space} ) {
            $test{url} .= '?space' . uri_escape( $q->{space} );
        }

        if ( exists $q->{last_results} and $q->{last_results} ) {
            my $results = delete $test{results};
            $test{results} = scalar @$results < $q->{last_results} ? [@$results] : [ @{$results}[ -$q->{last_results} .. -1 ] ];
        }
        elsif ( exists $q->{results} and !$q->{results} ) {
            delete $test{results};
        }

        if ( exists $test{results} ) {
            my @results;

            setlocale( LC_MESSAGES, $lang . '.UTF-8' );
            foreach my $result ( @{ $test{results} } ) {
                my $entry = Zonemaster::Logger::Entry->new( $result );

                my $message = $translator->translate_tag( $entry );
                utf8::decode( $message );

                push(
                    @results,
                    {
                        %$result,
                        message => $message
                    }
                );
            }
            setlocale( LC_MESSAGES, $self->{lang} . '.UTF-8' );

            $test{results} = \@results;
        }

        $self->Successful( $cb, \%test );
        return;
    }

    #
    # Query the database for the analyze.
    #

    $self->{db}->ReadAnalyze(
        $q->{space} ? ( space => $q->{space} ) : (),
        id => $q->{id},
        cb => sub {
            my ( $analyze ) = @_;

            # uncoverable branch true
            unless ( defined $self ) {

                # uncoverable statement
                return;
            }

            if ( $@ ) {
                $STAT{api}->{errors}++;

                if ( $@ eq ERR_ID_NOT_FOUND ) {
                    $self->Error(
                        $cb,
                        Lim::Error->new(
                            module  => $self,
                            code    => HTTP::Status::HTTP_NOT_FOUND,
                            message => $@
                        )
                    );
                    return;
                }

                # uncoverable branch false
                Lim::ERR and $self->{logger}->error( $@ );
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module => $self,
                        code   => HTTP::Status::HTTP_INTERNAL_SERVER_ERROR
                    )
                );
                return;
            }

            #
            # Construct the result
            #

            if ( exists $q->{last_results} and $q->{last_results} ) {
                my %test    = %{ $TEST{ $q->{id} } };
                my $results = delete $analyze->{results};
                $analyze->{results} = scalar @$results < $q->{last_results} ? [@$results] : [ @{$results}[ -$q->{last_results} .. -1 ] ];
            }
            elsif ( exists $q->{results} and !$q->{results} ) {
                delete $analyze->{results};
            }

            if ( exists $analyze->{results} ) {
                setlocale( LC_MESSAGES, $lang . '.UTF-8' );
                foreach my $result ( @{ $analyze->{results} } ) {
                    my $entry = Zonemaster::Logger::Entry->new( $result );
                    $result->{message} = $translator->translate_tag( $entry );
                    utf8::decode( $result->{message} );
                }
                setlocale( LC_MESSAGES, $self->{lang} . '.UTF-8' );
            }

            my ( @ns, @ds, @meta_data );

            if ( $analyze->{ns} ) {
                foreach my $ns ( @{ $analyze->{ns} } ) {
                    push(
                        @ns,
                        {
                            fqdn => $ns->{fqdn},
                            exists $ns->{ip} ? ( ip => $ns->{ip} ) : ()
                        }
                    );
                }
            }

            if ( $analyze->{ds} ) {
                foreach my $ds ( @{ $analyze->{ds} } ) {
                    push(
                        @ds,
                        {
                            keytag    => $ds->{keytag},
                            algorithm => $ds->{algorithm},
                            type      => $ds->{type},
                            digest    => $ds->{digest}
                        }
                    );
                }
            }

            if ( $analyze->{meta_data} ) {
                foreach my $meta_data ( @{ $analyze->{meta_data} } ) {
                    push(
                        @meta_data,
                        {
                            key   => $meta_data->{key},
                            value => $meta_data->{value}
                        }
                    );
                }
            }

            $self->Successful(
                $cb,
                {
                    id   => $analyze->{id},
                    fqdn => $analyze->{fqdn},
                    exists $analyze->{policy}
                    ? (
                        policy => {
                            name    => $analyze->{policy}->{name},
                            display => $analyze->{policy}->{display},
                            $analyze->{policy}->{description} ? ( description => $analyze->{policy}->{description} ) : ()
                        }
                      )
                    : (),
                    url => $base_url . '/zonalizer/' . uri_escape( $q->{version} ) . '/analysis/' . uri_escape( $analyze->{id} ) . ( $q->{space} ? '?space=' . uri_escape( $q->{space} ) : '' ),
                    status   => $analyze->{status},
                    progress => $analyze->{progress},
                    created  => $analyze->{created},
                    updated  => $analyze->{updated},
                    exists $analyze->{error}   ? ( error   => $analyze->{error} )   : (),
                    exists $analyze->{results} ? ( results => $analyze->{results} ) : (),
                    summary => {
                        notice   => $analyze->{summary}->{notice},
                        warning  => $analyze->{summary}->{warning},
                        error    => $analyze->{summary}->{error},
                        critical => $analyze->{summary}->{critical}
                    },
                    ipv4 => $analyze->{ipv4},
                    ipv6 => $analyze->{ipv6},
                    scalar @ns        ? ( ns        => \@ns )        : (),
                    scalar @ds        ? ( ds        => \@ds )        : (),
                    scalar @meta_data ? ( meta_data => \@meta_data ) : ()
                }
            );
        }
    );
    return;
}

=item ReadAnalyzeStatus

=cut

sub ReadAnalyzeStatus {
    my ( $self, $cb, $q ) = @_;
    my $real_self = $self;
    weaken( $self );
    $STAT{api}->{requests}++;

    unless ( $q->{version} == 1 ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_INVALID_API_VERSION
            )
        );
        return;
    }

    #
    # Check for analyze in memory.
    #

    if ( exists $TEST{ $q->{id} } ) {
        if ( $q->{space} ) {
            unless ( exists $TEST_SPACE{ $q->{id} }
                and $TEST_SPACE{ $q->{id} } eq $q->{space} )
            {
                $STAT{api}->{errors}++;
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module  => $self,
                        code    => HTTP::Status::HTTP_NOT_FOUND,
                        message => ERR_ID_NOT_FOUND
                    )
                );
                return;
            }
        }
        else {
            if ( exists $TEST_SPACE{ $q->{id} } ) {
                $STAT{api}->{errors}++;
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module  => $self,
                        code    => HTTP::Status::HTTP_NOT_FOUND,
                        message => ERR_ID_NOT_FOUND
                    )
                );
                return;
            }
        }

        $self->Successful(
            $cb,
            {
                status   => $TEST{ $q->{id} }->{status},
                progress => $TEST{ $q->{id} }->{progress},
                updated  => $TEST{ $q->{id} }->{updated}
            }
        );
        return;
    }

    #
    # Query the database for the analyze.
    #

    $self->{db}->ReadAnalyze(
        $q->{space} ? ( space => $q->{space} ) : (),
        id => $q->{id},
        cb => sub {
            my ( $analyze ) = @_;

            # uncoverable branch true
            unless ( defined $self ) {

                # uncoverable statement
                return;
            }

            if ( $@ ) {
                $STAT{api}->{errors}++;

                if ( $@ eq ERR_ID_NOT_FOUND ) {
                    $self->Error(
                        $cb,
                        Lim::Error->new(
                            module  => $self,
                            code    => HTTP::Status::HTTP_NOT_FOUND,
                            message => $@
                        )
                    );
                    return;
                }

                # uncoverable branch false
                Lim::ERR and $self->{logger}->error( $@ );
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module => $self,
                        code   => HTTP::Status::HTTP_INTERNAL_SERVER_ERROR
                    )
                );
                return;
            }

            #
            # Construct the result
            #

            $self->Successful(
                $cb,
                {
                    status   => $analyze->{status},
                    progress => $analyze->{progress},
                    updated  => $analyze->{updated}
                }
            );
        }
    );
    return;
}

=item DeleteAnalyze

=cut

sub DeleteAnalyze {
    my ( $self, $cb, $q ) = @_;
    my $real_self = $self;
    weaken( $self );
    $STAT{api}->{requests}++;

    unless ( $q->{version} == 1 ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_INVALID_API_VERSION
            )
        );
        return;
    }

    if ( exists $TEST{ $q->{id} } ) {
        if ( $q->{space} ) {
            unless ( exists $TEST_SPACE{ $q->{id} }
                and $TEST_SPACE{ $q->{id} } eq $q->{space} )
            {
                $STAT{api}->{errors}++;
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module  => $self,
                        code    => HTTP::Status::HTTP_NOT_FOUND,
                        message => ERR_ID_NOT_FOUND
                    )
                );
                return;
            }
        }
        else {
            if ( exists $TEST_SPACE{ $q->{id} } ) {
                $STAT{api}->{errors}++;
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module  => $self,
                        code    => HTTP::Status::HTTP_NOT_FOUND,
                        message => ERR_ID_NOT_FOUND
                    )
                );
                return;
            }
        }

        delete $TEST{ $q->{id} };
        delete $TEST_DB{ $q->{id} };
        delete $TEST_SPACE{ $q->{id} };

        $self->Successful( $cb );
        return;
    }

    $self->{db}->DeleteAnalyze(
        $q->{space} ? ( space => $q->{space} ) : (),
        id => $q->{id},
        cb => sub {

            # uncoverable branch true
            unless ( defined $self ) {

                # uncoverable statement
                return;
            }

            if ( $@ ) {
                $STAT{api}->{errors}++;

                if ( $@ eq ERR_ID_NOT_FOUND ) {
                    $self->Error(
                        $cb,
                        Lim::Error->new(
                            module  => $self,
                            code    => HTTP::Status::HTTP_NOT_FOUND,
                            message => $@
                        )
                    );
                    return;
                }

                # uncoverable branch false
                Lim::ERR and $self->{logger}->error( $@ );
                $self->Error(
                    $cb,
                    Lim::Error->new(
                        module => $self,
                        code   => HTTP::Status::HTTP_INTERNAL_SERVER_ERROR
                    )
                );
                return;
            }

            $self->Successful( $cb );
        }
    );
    return;
}

=item ReadPolicies

=cut

sub ReadPolicies {
    my ( $self, $cb, $q ) = @_;
    my $real_self = $self;
    weaken( $self );
    $STAT{api}->{requests}++;

    unless ( $q->{version} == 1 ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_INVALID_API_VERSION
            )
        );
        return;
    }

    my @policies;

    foreach ( values %{ $self->{collector_policy} } ) {
        push(
            @policies,
            {
                name    => $_->{name},
                display => $_->{display},
                $_->{description} ? ( description => $_->{description} ) : ()
            }
        );
    }

    $self->Successful( $cb, { policies => \@policies } );
    return;
}

=item ReadPolicy

=cut

sub ReadPolicy {
    my ( $self, $cb, $q ) = @_;
    my $real_self = $self;
    weaken( $self );
    $STAT{api}->{requests}++;

    unless ( $q->{version} == 1 ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_INVALID_API_VERSION
            )
        );
        return;
    }

    if ( $q->{name} and !exists $self->{collector_policy}->{ $q->{name} } ) {
        $STAT{api}->{errors}++;
        $self->Error(
            $cb,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_BAD_REQUEST,
                message => ERR_POLICY_NOT_FOUND
            )
        );
        return;
    }

    $self->Successful(
        $cb,
        {
            name    => $self->{collector_policy}->{ $q->{name} }->{name},
            display => $self->{collector_policy}->{ $q->{name} }->{display},
            $self->{collector_policy}->{ $q->{name} }->{description} ? ( description => $self->{collector_policy}->{ $q->{name} }->{description} ) : ()
        }
    );
    return;
}

=back

=head1 PRIVATE METHODS

=over 4

=item StoreAnalyze

=cut

sub StoreAnalyze {
    my ( $self, $id ) = @_;
    my $real_self = $self;
    weaken( $self );

    unless ( defined $id ) {
        $self->{logger}->error( 'called without $id' );
    }
    unless ( exists $TEST{$id} ) {
        $self->{logger}->error( 'called but $TEST{ $id } does not exist' );
        return;
    }
    unless ( exists $TEST_DB{$id} ) {
        $self->{logger}->error( 'called but $TEST_DB{ $id } does not exist' );
        return;
    }

    $self->{logger}->debug( 'Storing ', $id );

    $self->{db}->UpdateAnalyze(
        $TEST_SPACE{$id} ? ( space => $TEST_SPACE{$id} ) : (),
        analyze => {
            %{ $TEST_DB{$id} },
            %{ $TEST{$id} }
        },
        cb => sub {

            # uncoverable branch true
            unless ( defined $self ) {

                # uncoverable statement
                return;
            }

            if ( $@ ) {
                $self->{logger}->error( 'Unable to store ', $id, ' in database, analyze will be lost: ', $@ );
            }

            delete $TEST{$id};
            delete $TEST_DB{$id};
            delete $TEST_SPACE{$id};
        }
    );
    return;
}

=item GetTranslator

=cut

sub GetTranslator {
    my ( $self, $lang ) = @_;

    unless ( $lang ) {
        $lang = $self->{lang};
    }

    unless ( $lang =~ /^[a-z]{2}_[A-Z]{2}$/o and setlocale( LC_MESSAGES, $lang . '.UTF-8' ) ) {

        # uncoverable branch false
        Lim::ERR and $self->{logger}->error( 'Invalid language ', $lang );

        return (
            undef,
            undef,
            Lim::Error->new(
                module  => $self,
                code    => HTTP::Status::HTTP_UNSUPPORTED_MEDIA_TYPE,
                message => ERR_INVALID_LANG
            )
        );
    }

    setlocale( LC_MESSAGES, $self->{lang} . '.UTF-8' );

    return ( $TRANSLATOR, $lang );
}

=item StartCollector

=cut

sub StartCollector {
    my ( $self, %args ) = @_;
    my $real_self = $self;
    weaken( $self );

    unless ( defined $args{exec} ) {
        confess 'exec not defined';
    }
    unless ( ref( $args{on_eof} ) eq 'CODE' ) {
        confess 'on_eof is not CODE';
    }

    my $json = JSON::XS->new->utf8;
    my ( $read, $write ) = AnyEvent::Util::portable_pipe;
    my $hdl = AnyEvent::Handle->new( fh => $write );
    my %id;

    Lim::DEBUG and $self->{logger}->debug(
        'open ',
        join(
            ' ',
            $args{exec},
            $args{config}     ? ( '--config',     $args{config} )     : (),
            $args{policy}     ? ( '--policy',     $args{policy} )     : (),
            $args{sourceaddr} ? ( '--sourceaddr', $args{sourceaddr} ) : (),
            $args{threads}    ? ( '--threads',    $args{threads} )    : ()
        )
    );

    my $cv;
    $cv = AnyEvent::Util::run_cmd(
        [
            $args{exec},
            $args{config}     ? ( '--config',     $args{config} )     : (),
            $args{policy}     ? ( '--policy',     $args{policy} )     : (),
            $args{sourceaddr} ? ( '--sourceaddr', $args{sourceaddr} ) : (),
            $args{threads}    ? ( '--threads',    $args{threads} )    : (),
        ],
        '>' => sub {
            unless ( defined $self ) {
                return;
            }

            my @entries;
            eval {
                @entries = $json->incr_parse( @_ );
                foreach ( @entries ) {
                    unless ( ref( $_ ) eq 'HASH' and $_->{_id} ) {
                        die;
                    }

                    unless ( $id{ $_->{_id} } ) {
                        Lim::WARN and $self->{logger}->warn( 'collector received data for unknown id' );
                        next;
                    }

                    if ( $id{ $_->{_id} }->( $_ ) ) {
                        delete $id{ $_->{_id} };
                    }
                }
            };
            if ( $@ ) {
                $hdl->destroy;
                $cv->croak( $@ );
            }
        },
        '2>' => sub {
            unless ( defined $self and scalar @_ and defined $_[0] ) {
                return;
            }

            Lim::DEBUG and $self->{logger}->debug( 'collector: ', @_ );
        },
        '<' => $read,
    );

    $cv->cb(
        sub {
            unless ( defined $self ) {
                return;
            }

            eval { shift->recv; };
            if ( $@ ) {
                Lim::ERR and $self->{logger}->error( 'collector: ', $@ );
            }

            foreach ( values %id ) {
                $_->();
            }

            close( $read );
            $hdl->destroy;
            $args{on_eof}->();
        }
    );

    return sub {
        my ( $cb, %args ) = @_;

        unless ( defined $self ) {
            return;
        }

        unless ( ref( $cb ) eq 'CODE' and $args{id} and !exists $id{ $args{id} } ) {
            confess 'collector->analyze called incorrectly';
        }

        eval { $hdl->push_write( $json->encode( \%args ) . "\n" ); };
        if ( $@ or $hdl->destroyed ) {
            $cb->();
            return;
        }

        $id{ $args{id} } = $cb;
    };
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim-plugin-zonalizer/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Plugin::Zonalizer::Server

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim-plugin-zonalizer/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2016 Jerry Lundström
Copyright 2015-2016 IIS (The Internet Foundation in Sweden)

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Lim::Plugin::Zonalizer::Server
