package Locale::TextDomain::OO::Extract::Process; ## no critic (TidyCode)

use strict;
use warnings;
use Carp qw(confess);
use Clone qw(clone);
use Class::Load qw(load_class);
use Locale::TextDomain::OO::Util::JoinSplitLexiconKeys;
use Moo;
use MooX::StrictConstructor;
use MooX::Types::MooseLike::Base qw(HashRef Str);
use Set::Scalar;
use namespace::autoclean;

our $VERSION = '2.015';

has category => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => q{},
);

has domain => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => q{},
);

has language => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => 'i-default',
);

has project => (
    is  => 'rw',
    isa => sub {
        my $project = shift;
        defined $project
            or return;
        return Str->($project);
    },
);

has lexicon_ref => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    default => sub { {} },
);

has plugin_ref => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    default => sub { { po => 'PO' } },
);

has _plugin_object_ref => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {} },
);

sub add_plugin {
    my ( $self, $plugin_alias, $plugin ) = @_;

    $plugin_alias
        or confess 'Plugin alias expected';
    $plugin
        or confess 'Plugin name expected';
    delete $self->_plugin_object_ref->{$plugin_alias};
    $self->plugin_ref->{$plugin_alias} = $plugin;

    return;
}

sub _plugin {
    my ( $self, $plugin_alias ) = @_;

    $plugin_alias
        or confess 'Undef is not a plugin alias';
    my $plugin_object_ref = $self->_plugin_object_ref;
    if ( exists $plugin_object_ref->{$plugin_alias} ) {
        my $object = $plugin_object_ref->{$plugin_alias};
        $object->clear;
        METHOD:
        for my $method ( qw( category domain language lexicon_ref project ) ) {
            my $value = $self->$method;
            defined $value
                or next METHOD;
            $object->$method($value);
        }
        return $object;
    }
    my $plugin = $self->plugin_ref->{$plugin_alias}
        or confess "Unknown plugin alias $plugin_alias";
    my $class = $plugin =~ s{ \A [+] }{}xms
        ? $plugin
        : "Locale::TextDomain::OO::Extract::Process::Plugin::$plugin";
    my $object = load_class($class)->new(
        map {
            defined $self->$_
                ? ( $_ => $self->$_ )
                : ();
        }
        qw( category domain language lexicon_ref project )
    );
    $plugin_object_ref->{$plugin_alias} = $object;

    return $object;
}

sub slurp {
    my ( $self, $plugin_alias, $filename ) = @_;

    $self->_plugin($plugin_alias)->slurp($filename);

    return;
}

sub spew {
    my ( $self, $plugin_alias, $filename ) = @_;

    $self->_plugin($plugin_alias)->spew($filename);

    return;
}

sub remove_all_reference {
    my $self = shift;

    my $lexicon_ref = $self->lexicon_ref;
    for my $message_ref ( values %{$lexicon_ref} ) {
        for my $value_ref ( values %{$message_ref} ) {
            delete $value_ref->{reference};
        }
    }

    return;
}

sub remove_all_automatic {
    my $self = shift;

    my $lexicon_ref = $self->lexicon_ref;
    for my $message_ref ( values %{$lexicon_ref} ) {
        for my $value_ref ( values %{$message_ref} ) {
            delete $value_ref->{automatic};
        }
    }

    return;
}

sub remove_all_non_referenced {
    my $self = shift;

    my $lexicon_ref = $self->lexicon_ref;
    for my $message_ref ( values %{$lexicon_ref} ) {
        MESSAGE_KEY:
        for my $message_key ( keys %{$message_ref} ) {
            length $message_key
                or next MESSAGE_KEY; # skip header
            my $has_reference
                = exists $message_ref->{$message_key}->{reference}
                && $message_ref->{$message_key}->{reference} =~ m{\S}xms;
            $has_reference
                or delete $message_ref->{$message_key};
        }
    }

    return;
}

sub merge_extract {
    my ( $self, $arg_ref ) = @_;

    my $extract_lexicon_ref = $arg_ref->{lexicon_ref}
        or confess 'Parameter lexicon_ref expected';
    ref $extract_lexicon_ref eq 'HASH'
        or confess 'Parameter lexicon_ref is not a hash reference';

    my $key_util = Locale::TextDomain::OO::Util::JoinSplitLexiconKeys->instance;
    # extracted to language i-default
    my $extract_lexicon_key = $key_util->join_lexicon_key({(
        map {
            $_ => $arg_ref->{$_};
        }
        qw( category domain project )
    )});
    # merged to real language
    my $lexicon_key = $key_util->join_lexicon_key({(
        map {
            $_ => $self->$_;
        }
        qw( category domain language project )
    )});

    my $message_ref  = $self->lexicon_ref->{$lexicon_key} ||= {};
    my $message_keys = Set::Scalar->new( keys %{$message_ref} );
    my $extract_message_ref  = $extract_lexicon_ref->{$extract_lexicon_key};
    my $extract_message_keys = Set::Scalar->new( keys %{$extract_message_ref} );
    my $skip_new_messages = $arg_ref->{skip_new_messages};
    my @new_message_keys
        = ref $skip_new_messages ne 'HASH'
        # simple
        ? (
            $skip_new_messages
            # bool parameter true
            ? ()
            : $extract_message_keys->difference($message_keys)->elements
        )
        # extended
        : ! $skip_new_messages->{on}
        # hash parameter false
        ? $extract_message_keys->difference($message_keys)->elements
        : do {
            my $to_regex = sub {
                my $any = shift;
                my @parts
                    = map { ref $_ eq 'Regexp' ? $_ : qr{\Q$_\E}xmsi }
                    grep { defined && length }
                    ref $any eq 'ARRAY' ? @{$any} : $any;
                return @parts
                    ? do {
                        my $joined = join ' | ', @parts;
                        qr{ $joined }xms;
                    }
                    : qr{ (?!) }xms;
            };
            my $regex     = $to_regex->( $skip_new_messages->{no_skip_for} );
            my $not_regex = $to_regex->( $skip_new_messages->{but_skip_for} );

            grep { $_ =~ $regex && $_ !~ $not_regex }
            $extract_message_keys->difference($message_keys)->elements;
        };
    my @changed_message_keys = $extract_message_keys->intersection($message_keys)->elements;

    # merge header
    my $header_arg_ref = $arg_ref->{header_ref};
    if ($header_arg_ref) {
        # overwrite them
        if ( ref $arg_ref->{header_ref} eq 'HASH' ) {
            $message_ref->{ q{} } = clone($header_arg_ref);
        }
        # manipulate them
        elsif ( ref $header_arg_ref eq 'CODE' ) {
            local $_ = $message_ref->{ q{} } || {};
            $header_arg_ref->();
            $message_ref->{ q{} } = clone($_);
        }
    }

    MESSAGE_KEY:
    for my $message_key (@new_message_keys) {
        length $message_key
            or next MESSAGE_KEY;
        $message_ref->{$message_key}
            = clone( $extract_message_ref->{$message_key} );
    }
    MESSAGE_KEY:
    for my $message_key (@changed_message_keys) {
        length $message_key
            or next MESSAGE_KEY;
        my $extract_message_value_ref
            = clone( $extract_message_ref->{$message_key} );
        @{ $message_ref->{$message_key} }{ keys %{$extract_message_value_ref} }
            = values %{ $extract_message_value_ref };
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME
Locale::TextDomain::OO::Extract::Process
- Prepare PO/MO files for extraction and store them back after extraction

$Id: Process.pm 719 2018-09-21 12:58:00Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/extract/trunk/lib/Locale/TextDomain/OO/Extract/Process.pm $

=head1 VERSION

2.015

=head1 DESCRIPTION

Prepare PO/MO files for extraction and store them back after extraction.

=head1 SYNOPSIS

=head2 build a process object

    use Locale::TextDomain::OO::Extract::Perl; # subclass Perl
    use Path::Tiny qw(path);

Set in constructor all static values.
Set all other in loop.

    my $process = Locale::TextDomain::OO::Extract::Process->new(
        # set all static things here, all dynamics in loops
        project     => 'my project',     # for special cases
                                         # set or default undef is used
        category    => 'LC_MESSAGES',    # for special cases
                                         # set or default q{} is used
        domain      => 'my domain',      # text domain
                                         # set or default q{} is used
        language    => 'en',             # mostly dynamic and not set here
                                         # set or the default 'i-default' is used
        lexicon_ref => $my_own_hash_ref, # mostly not set
        plugin_ref  => {                 # depends on read/write files
            po  => 'PO',                 # default
            mo  => 'MO',
            foo => '+My::FooPlugin',     # with full class name
        },
    );

=head2 read all existing PO files

    for ( @po_files ) {
        $process->project('my project');
        $process->category('LC_MESSAGES');
        $process->domain('my domain');
        $process->language('en');
        $process->slurp( po => $_ );
    }

=head2 strip all references

This are the C<#:> comments in PO files.

    $process->remove_all_reference;

=head2 strip all automatic comments

This are the C<#.> comments in PO files.

    $process->remove_all_automatic;

=head2 extract e.g. all *.pl and *.pm files and so fill with new references

    my $extract = Locale::TextDomain::OO::Extract::Perl->new;
    for ( @perl_files ) {
        $extract->clear;
        $extract->project('my extract project');
        $exttact->category('my extract category');
        $extract->domain('my extract domain');
        # language is i-default
        $extract->filename($_);
        $extract->content_ref( \( path($_)->slurp_utf8 ) );
        $extract->extract;
    }

=head2 merge extracted data

Merge of new or changed data from extract lexicon to process lexicon.
Mostly the extract project/category/domain is the same like
process project/category/domain.
But in can be different.

    $process->merge_extract({
        lexicon_ref       => $extract->lexicon_ref,
        project           => 'my extract project',
        category          => 'my extract category',
        domain            => 'my extract domain',
        # extract language is i-default
        # skip region if region file is only the difference, e.g. to language de
        skip_new_messages => $process->language eq 'de-at',
        # or extended
        skip_new_messages => {
            on           => $process->language eq 'de-at'
            no_skip_for  => # arrayref or scalar with string or regex
                            [ '.domain.de', '+49', qr{ ... }xmsi ) ],
            but_skip_for => # same like before but filter out false positive
                            'Fax: ',
        },
    });

=head2 write back all PO files

    for ( @po_files ) {
        $process->clear;
        $process->project('my project');
        $process->category('LC_MESSAGES');
        $process->domain('my domain');
        $process->language('en');
        $process->spew( po => $_ );
    }

=head2 now translate all po files

Do it.

=head2 read agian all existing PO files

    for ( @po_files ) {
        $process->project('my project');
        $process->category('LC_MESSAGES');
        $process->domain('my domain');
        $process->language('en');
        $process->slurp( po => $_ );
    }

=head2 clean all entries with no reference

This are the C<#:> comments in PO files.

    $process->remove_all_non_referenced;

=head2 write back all PO files and also as MO file

    for ( @po_files ) {
        $process->clear;
        $process->project('my project');
        $process->category('LC_MESSAGES');
        $process->domain('my domain');
        $process->language('en');
        $process->spew( po => $_ );
        ( my $mo_file = $_ ) =~ s{ [.] po \z }{.mo}xms;
        $process->spew( mo => $mo_file );
    }

=head1 SUBROUTINES/METHODS

=head2 method new, category, domain, language, project, lexicon_ref, plugin_ref

see SYNOPSIS

=head2 method add_plugin

Needs a plugin name amd a package name.
If no + is written the Package name is prefixed by
"Locale::TextDomain::OO::Extract::Process::Plugin::".

    $process->add_plugin( mo  => 'MO' );
    $process->add_plugin( bar => '+My::BarPlugin' );

=head2 method slurp

Slurp a file and put the data into the lexicon_ref.

    $process->slurp( po => 'filename.po' );

=head2 method spew

Spew a file with data of lexicon_ref.

    $process->spew( mo => 'filename.mo');

=head2 method remove_all_reference

Strips all references.
References are here gettext references,
the filename and line of file the extractor has found.

    $process->remove_all_reference;

=head2 method remove_all_automatic

Strips all automatic comments.

    $process->remove_all_automatic;

=head2 method remove_all_non_referenced

All entries with no reference are no longer in source
because the extractor has not found.
So there is no need to translate this phrases.

    $process->remove_all_non_referenced;

=head2 method merge_extract

The extractor extracts for language i-default.
That is running one time for all files.
But every language needs the new extraction data.
So all new and changed data will be merged to any language.
For sublanguages/regions it is possible to skip.

    $process->merge_extract({
        lexicon_ref         => $extract->lexicon_ref,
        # all following optional
        category            => 'category during extraction',
        domain              => 'domain during extraction',
        project             => 'project during extraction',
        # simple
        skip_new_messages   => $boolean,
        # or extended
        skip_new_messages   => {
            on           => $boolean,
            no_skip_     => $arrayref_or_scalar_with_string_or_regex,
            but_skip_for => $arrayref_or_scalar_with_string_or_regex,
        },
    });

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Carp|Carp>

L<Clone|Clone>

L<Class::Load|Class::Load>

L<Locale::TextDomain::OO::Util::JoinSplitLexiconKeys|Locale::TextDomain::OO::Util::JoinSplitLexiconKeys>

L<Moo|Moo>

L<MooX::StrictConstructor|MooX::StrictConstructor>

L<MooX::Types::MooseLike::Base|MooX::Types::MooseLike::Base>

L<Set::Scalar|Set::Scalar>

L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO::Extract|Locale::TextDoamin::OO::Extract>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 - 2018,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
