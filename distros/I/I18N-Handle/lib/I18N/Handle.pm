package I18N::Handle;
use warnings;
use strict;
use Moose;
use I18N::Handle::Locale;
use File::Find::Rule;
use Locale::Maketext::Lexicon ();

our $VERSION = '0.051';

has base => ( is => 'rw' );

has accept_langs => (
    is => 'rw',
    isa => 'ArrayRef',
    traits => [ 'Array' ],
    handles => { 
        'add_accept' => 'push',
        'accepted' => 'elements'
    },
    default => sub { [] } );

has langs => ( 
    is => 'rw' , 
    isa => 'ArrayRef' , 
    traits => [ 'Array' ],
    handles => { 
        add_lang => 'push',
        can_speak => 'elements'
    },
    default => sub { [] }
    );  # can speaks

has current => ( is => 'rw' );  # current language

has fallback_lang => ( is => 'rw' );

our $singleton;

sub BUILDARGS {
    my $self = shift;
    my %args = @_;
    return \%args;
}

sub BUILD {
    my $self = shift;
    my %args = %{ +shift };

    my %import;
    if( $args{po} ) {
        # XXX: check po for ref
        $args{po} = ( ref $args{po} eq 'ARRAY' ) ? $args{po} : [ $args{po} ];

        my %langs = $self->_scan_po_files( $args{po} );

        # $self->{_langs} = [ keys %langs ];

        $self->add_lang( keys %langs );

        %import = ( %import, %langs );
    }

    if( $args{locale} ) {
        $args{locale} = ( ref $args{po} eq 'ARRAY' ) ? $args{locale} : [ $args{locale} ];
        my %langs = $self->_scan_locale_files( $args{locale} );

        # $self->{_langs} = [ keys %langs ];

        $self->add_lang( keys %langs );

        %import = ( %import, %langs );
    }

    %import = ( %import, %{ $args{import} } ) if( $args{import} );

    for my $format ( qw(Gettext Msgcat Slurp Tie) ) {
        next unless $args{ $format };
        my $list = $args{ $format };
        while ( my ($tag,$arg) = each %$list ) {

            $tag = $self->_unify_langtag( $tag );

            if ( ! ref $arg ) {
                $import{ $tag } = [ $format => $arg ]
            }
            elsif ( ref $arg eq 'ARRAY' ) {
                $import{ $tag } = [ map { $format => $_ } @$arg ]
            }

            # push @{ $self->{_langs} }, $self->_unify_langtag( $tag );
            $self->add_lang( $tag );
        }
    }

    $import{_style} = $args{style} if( $args{style} );

    $self->base( I18N::Handle::Locale->new( \%import ) );
    $self->base->init;

    return $self if $args{no_global_loc};

    my $loc_name = $args{'loc'} || '_';
    if( $args{loc_func} ) {
        my $loc_func = $args{loc_func};
        {
            no strict 'refs';
            no warnings 'redefine';
            *{ '::'.$loc_name } = sub { 
                return $loc_func->( $self, $self->base->get_current_handle );
            };
        }
    } else {
        $self->install_global_loc( $loc_name , $self->base->get_current_handle );
    }
    return $self;
}


sub singleton {
    my ($class,%args) = @_;
    return $singleton ||= $class->new( %args );
}

# translate zh_TW => zh-tw
# see Locale::Maketext , 
#      ·   $lh = YourProjClass->get_handle( ...langtags... ) || die "lg-handle?";
#          This tries loading classes based on the language-tags you give (like "("en-US", "sk", "kon", "es-MX", "ja", "i-klingon")",
#          and for the first class that succeeds, returns YourProjClass::language->new().

sub _unify_langtag {
    my ($self,$tag) = @_;
    $tag =~ tr<_A-Z><-a-z>; # lc, and turn _ to -
    $tag =~ tr<-a-z0-9><>cd;  # remove all but a-z0-9-
    return $tag;
}

sub _scan_po_files {
    my ($self,$dir) = @_;
    my @files = File::Find::Rule->file->name("*.po")->in(@$dir);
    my %langs;
    for my $file ( @files ) {
        my ($tag) = ($file =~ m{([a-z]{2}(?:_[a-zA-Z]{2})?)\.po$}i );
        $langs{ $self->_unify_langtag($tag )  } = [ Gettext => $file ];
    }
    return %langs;
}

sub _scan_locale_files {
    my ($self,$dir) = @_;
    my @files = File::Find::Rule->file->name("*.mo")->in( @$dir );
    my %langs;
    for my $file ( @files ) {
        my ($tag) = ($file =~ m{([a-z]{2}(?:_[a-zA-Z]{2})?)/LC_MESSAGES/}i );
        $langs{ $self->_unify_langtag($tag )  } = [ Gettext => $file ];
    }
    return %langs;
}

sub speaking {
    my $self = shift;
    return $self->current();
}

sub speak {
    my ($self,$lang) = @_;
    if( grep { $lang eq $_ } $self->can_speak ) {
        $self->current( $lang );
        $self->base->speak( $lang );
    } else {
        if ( $self->fallback_lang ) {
            $self->current( $self->fallback_lang );
            $self->base->speak( $self->fallback_lang );
        } 
    }
    return $self;
}

sub accept {
    my ($self,@langs) = @_;
    for my $lang ( map { $self->_unify_langtag( $_ ) } @langs ) { 
        if( grep { $lang eq $_ } $self->can_speak ) {
            $self->add_accept( $lang );
        } else {
            warn "Not accept language $lang..";
        }
    }
    return $self;
}

# XXX: check locale::maketext fallback option.
sub fallback {
    my ($self,$lang) = @_;
    $self->fallback_lang( $lang );
    return $self;
}

sub install_global_loc {
    my ( $self, $loc_name ) = @_;
    my $loc_method = $self->base->get_loc_method();
    {
        no strict 'refs';
        no warnings 'redefine';
        *{ '::'.$loc_name } = $loc_method;
    }
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

I18N::Handle - A common i18n handler for web frameworks and applications.

=head1 DESCRIPTION

B<***THIS MODULE IS STILL IN DEVELOPMENT***>

L<I18N::Handle> is a common handler for web frameworks and applications.

I18N::Handle also provides exporting a global loc function to make localization, 
the default loc function name is C<"_">. To change the exporting loc function name
, please use C<loc> option.

The difference between I18N::Handle and L<Locale::Maketext> is that
I18N::Handle automatically does most things for you, and it provides simple API
like C<speak>, C<can_speak> instead of C<get_handle>, C<languages>.

To generate po/mo files, L<App::I18N> is an utility for this, App::I18N is a
command-line tool for parsing, exporting, managing, editing, translating i18n
messages. See also L<App::I18N>.

=head1 SYNOPSIS

Ideas are welcome. just drop me a line.

option C<import> takes the same arguments as L<Locale::Maketext::Lexicon> takes.
it's I<language> => [ I<format> => I<source> ].
    
    use I18N::Handle;
    my $hl = I18N::Handle->new( 
                import => {
                        en => [ Gettext => 'po/en.po' ],
                        fr => [ Gettext => 'po/fr.po' ],
                        ja => [ Gettext => 'po/ja.po' ],
                })->accept( qw(en fr) )->speak( 'en' );

Or a simple way to import gettext po files:
This will transform the args to the args that C<import> option takes:

    use I18N::Handle;
    my $hl = I18N::Handle->new( 
                Gettext => {
                        en => 'po/en.po',
                        fr => 'po/fr.po',
                        ja => [ 'po/ja.po' , 'po2/ja.po' ],
                })->accept( qw(en fr) )->speak( 'en' );


    print _('Hello world');

    $hl->speak( 'fr' );
    $hl->speak( 'ja' );
    $hl->speaking;  # return 'ja'

    my @langs = $hl->can_speak();  # return 'en', 'fr', 'ja'

=head1 OPTIONS

=over 4 

=item I<format> => { I<language> => I<source> , ... }

Format could be I<Gettext | Msgcat | Slurp | Tie>.

    use I18N::Handle;
    my $hl = I18N::Handle->new( 
                Gettext => {
                        en => 'po/en.po',
                        fr => 'po/fr.po',
                        ja => [ 'po/ja.po' , 'po2/ja.po' ],
                });
    $hl->speak( 'en' );

=item C<po> => 'I<path>' | [ I<path1> , I<path2> ]

Suppose you have these files:

    po/en.po
    po/zh_TW.po

When using:

    I18N::Handle->new( po => 'po' );

will be found. can you can get these langauges:

    [ en , zh-tw ]

=item C<locale> => 'path' | [ path1 , path2 ]


=item C<import> => Arguments to L<Locale::Maketext::Lexicon>

=back

=head1 OPTIONAL OPTIONS

=over 4

=item no_global_loc => bool

Do not install global locale method C<"_">. 

=item style => style  ... (Optional)

The style could be C<gettext>.

=item loc => global loc function name (Optional)

The default global loc function name is C<_>. 

    loc => 'loc'

=item C<loc_func> => I<CodeRef>  (Optional)

Use a custom global localization function instead of default localization
function.

    loc_func => sub {
            my ($self,$lang_handle) = @_;

            ...

            return $text;
    }

=back

=head1 USE CASES

=head2 Handling po files

    $hl = I18N::Handle->new( 
            po => 'path/to/po',
            style => 'gettext'          # use gettext style format (default)
                )->speak( 'en' );

    print _('Hello world');


=head2 Handling locale

If you need to bind the locale directory structure like this:

    path/to/locale/en/LC_MESSAGES/app.po
    path/to/locale/en/LC_MESSAGES/app.mo
    path/to/locale/zh_tw/LC_MESSAGES/app.po
    path/to/locale/zh_tw/LC_MESSAGES/app.mo

You can just pass the C<locale> option:

    $hl = I18N::Handle->new(
            locale => 'path/to/locale'
            )->speak( 'en_US' );

or just use C<import>:

    $hl = I18N::Handle->new( 
            import => { '*' => 'locale/*/LC_MESSAGES/hello.mo'  } );

=head2 Handling json files

B<not implemented yet>

Ensure you have json files:

    json/en.json
    json/fr.json
    json/ja.json

Then specify the C<json> option:

    $hl = I18N::Handle->new( json => 'json' );

=head2 Singleton

If you need a singleton L<I18N::Handle>, this is a helper function to return
the singleton object:

    $hl = I18N::Handle->singleton( locale => 'path/to/locale' );

In your applications, might be like this:

    sub get_i18n {
        my $class = shift;
        return I18N::Handle->singleton( ... options ... )
    }


=head2 Connect to a remote i18n server

B<not implemented yet>

Connect to a translation server:

    $handle = I18N::Handle->new( 
            server => 'translate.me' )->speak( 'en_US' );


=head2 Binding with database

B<not implemented yet>

Connect to a database:

    $handle = I18N::Handle->new(
            dsn => 'DBI:mysql:database=$database;host=$hostname;port=$port;'
            );

=head2 Binding with Google translation service

B<not implemented yet>

Connect to google translation:

    $handle = I18N::Handle->new( google => "" );

=head2 Exporting loc function to Text::Xslate

    my $tx = Text::Xslate->new( 
        path => ['templates'], 
        cache_dir => ".xslate_cache", 
        cache => 1,
        function => { "_" => \&_ } );

Then you can use C<_> function inside your L<Text::Xslate> templates:

    <: _('Hello') :>

=head1 PUBLIC METHODS 

=head2 new

=head2 singleton( I<options> )

If you need a singleton L<I18N::Handle>, this is a helper function to return
the singleton object.

=head2 speak( I<language> )

setup current language. I<language>, can be C<en>, C<fr> and so on..

=head2 speaking()

get current speaking language name.

=head2 can_speak()

return a list that currently supported.

=head2 accept( I<language name list> )

setup accept languages.

    $hl->accpet( qw(en fr) );

=head2 fallback( I<language> )

setup fallback language. when speak() fails , fallback to this language.

    $hl->fallback( 'en' );

=head1 PRIVATE METHODS

=head2 _unify_langtag

=head2 _scan_po_files

=head2 _scan_locale_files






=head1 AUTHOR

Yoan Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

L<App::I18N>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
