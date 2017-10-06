
package Importer::Zim::Utils;
$Importer::Zim::Utils::VERSION = '0.8.0';
# ABSTRACT: Utilities for Importer::Zim backends

use 5.010001;

our @EXPORT_OK = qw(DEBUG carp croak);

BEGIN {
    my $v = $ENV{IMPORTER_ZIM_DEBUG} || 0;
    *DEBUG = sub () {$v};
}

sub carp  { require Carp; goto &Carp::carp; }
sub croak { require Carp; goto &Carp::croak; }

### import / unimport machinery

BEGIN {
    my $v
      = $ENV{IMPORTER_ZIM_NO_LEXICAL}
      ? !1
      : !!eval 'use Sub::Inject 0.2.0 (); 1';
    *USE_LEXICAL_SUBS = sub () {$v};
}

sub import {
    my $exports = shift->_get_exports(@_);

    if (USE_LEXICAL_SUBS) {
        @_ = %$exports;
        goto &Sub::Inject::sub_inject;
    }

    my $caller = caller;
    *{ $caller . '::' . $_ } = $exports->{$_} for keys %$exports;
}

sub unimport {
    my $exports = shift->_get_exports(@_);

    return if USE_LEXICAL_SUBS;

    my $caller = caller;
    delete ${"${caller}::"}{$_} for keys %$exports;
}

# BEWARE! unimport() will nuke the entire glob associated to
# an imported subroutine (if USE_LEXICAL_SUBS is false).
# So don't use scalar / hash / array variables with the same
# names as any of the symbols in @EXPORT_OK in the user modules.

sub _get_exports {
    my $class = shift;

    state $EXPORTABLE = { map { $_ => \&{$_} } @EXPORT_OK };

    my ( %exports, @bad );
    for (@_) {
        push( @bad, $_ ), next unless my $sub = $EXPORTABLE->{$_};
        $exports{$_} = $sub;
    }
    if (@bad) {
        my @carp;
        push @carp, qq["$_" is not exported by the $class module\n] for @bad;
        croak(qq[@{carp}Can't continue after import errors]);
    }
    return \%exports;
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Importer::Zim::Utils qw(DEBUG carp croak);
#pod     ...
#pod     no Importer::Zim::Utils qw(DEBUG carp croak);
#pod
#pod =head1 DESCRIPTION
#pod
#pod     "For longer than I can remember, I've been looking for someone like you."
#pod       – Tak
#pod
#pod No public interface.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Importer::Zim>
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Importer::Zim::Utils - Utilities for Importer::Zim backends

=head1 VERSION

version 0.8.0

=head1 SYNOPSIS

    use Importer::Zim::Utils qw(DEBUG carp croak);
    ...
    no Importer::Zim::Utils qw(DEBUG carp croak);

=head1 DESCRIPTION

    "For longer than I can remember, I've been looking for someone like you."
      – Tak

No public interface.

=head1 SEE ALSO

L<Importer::Zim>

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
