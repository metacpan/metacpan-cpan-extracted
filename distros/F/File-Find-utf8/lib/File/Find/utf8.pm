package File::Find::utf8;
use strict;
use warnings;
use 5.010; # state

# ABSTRACT: Fully UTF-8 aware File::Find
our $VERSION = '0.014'; # VERSION

#pod =begin :prelude
#pod
#pod =for test_synopsis
#pod my @directories_to_search;
#pod
#pod =end :prelude
#pod
#pod =head1 SYNOPSIS
#pod
#pod     # Use the utf-8 versions of find and finddepth
#pod     use File::Find::utf8;
#pod     find(\&wanted, @directories_to_search);
#pod
#pod     # Revert back to non-utf-8 versions
#pod     no File::Find::utf8;
#pod     finddepth(\&wanted, @directories_to_search);
#pod
#pod     # Export only the find function
#pod     use File::Find::utf8 qw(find);
#pod     find(\&wanted, @directories_to_search);
#pod
#pod     # Export no functions
#pod     use File::Find::utf8 qw(:none); # NOT "use File::Find::utf8 qw();"!
#pod     File::Find::find(\&wanted, @directories_to_search);
#pod
#pod =head1 DESCRIPTION
#pod
#pod While the original L<File::Find> functions are capable of handling
#pod UTF-8 quite well, they expect and return all data as bytes, not as
#pod characters.
#pod
#pod This module replaces the L<File::Find> functions with fully UTF-8
#pod aware versions, both expecting and returning characters.
#pod
#pod B<Note:> Replacement of functions is not done on DOS, Windows, and OS/2
#pod as these systems do not have full UTF-8 file system support.
#pod
#pod =head2 Behaviour
#pod
#pod The module behaves as a pragma so you can use both C<use
#pod File::Find::utf8> and C<no File::Find::utf8> to turn utf-8 support on
#pod or off.
#pod
#pod By default, both find() and finddepth() are exported (as with the original
#pod L<File::Find>), if you want to prevent this, use C<use File::Find::utf8
#pod qw(:none)>. (As all the magic happens in the module's import function,
#pod you can not simply use C<use File::Find::utf8 qw()>)
#pod
#pod L<File::Find> warning levels are properly propagated. Note though that
#pod for propagation of fatal L<File::Find> warnings, Perl 5.12 or higher
#pod is required (or the appropriate version of L<warnings>).
#pod
#pod =head1 COMPATIBILITY
#pod
#pod The filesystems of Dos, Windows, and OS/2 do not (fully) support
#pod UTF-8. The L<File::Find> function will therefore not be replaced on these
#pod systems.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * L<File::Find> -- The original module.
#pod * L<Cwd::utf8> -- Fully utf-8 aware version of the L<Cwd> functions.
#pod * L<utf8::all> -- Turn on utf-8, all of it.
#pod   This was also the module I first added the utf-8 aware versions of
#pod   L<Cwd> and L<File::Find> to before moving them to their own package.
#pod
#pod =cut

use File::Find ();
use Encode ();

# Holds the pointers to the original version of redefined functions
state %_orig_functions;

# Current (i.e., this) package
my $current_package = __PACKAGE__;

# Original package (i.e., the one for which this module is replacing the functions)
my $original_package = $current_package;
$original_package =~ s/::utf8$//;

require Carp;
$Carp::Internal{$current_package}++; # To get warnings reported at correct caller level

#pod =attr $File::Find::utf8::SPECIALVARS
#pod
#pod By default C<File::Find::utf8> only decodes the I<normal>
#pod L<File::Find> variables C<$_>, C<$File::Find::name>,
#pod C<$File::Find::dir>, and (when C<follow> or C<follow_fast> is in
#pod effect) C<$File::Find::fullname> for use in the C<preprocess>,
#pod C<wanted>, and C<postporcess> functions.
#pod
#pod If for any reason (e.g., compatibility with find.pl or find2perl) you
#pod also need the I<special> variables C<$File::Find::topdir>,
#pod C<$File::Find::topdev>, C<$File::Find::topino>,
#pod C<$File::Find::topmode>, and C<$File::Find::topnlink> to be decoded,
#pod specify C<local $File::Find::utf8::COMPATILBILITY = 1;> in your
#pod code. The extra decoding that needs to happen will impact performance
#pod though, so use only when absolutely necessary.
#pod
#pod =cut

our $SPECIALVARS = 0;

#pod =attr $File::Find::utf8::UTF8_CHECK
#pod
#pod By default C<File::Find::utf8> marks decoding errors as fatal (default value
#pod for this setting is C<Encode::FB_CROAK>). If you want, you can change this by
#pod setting C<File::Find::utf8::UTF8_CHECK>. The value C<Encode::FB_WARN> reports
#pod the encoding errors as warnings, and C<Encode::FB_DEFAULT> will completely
#pod ignore them. Please see L<Encode> for details. Note: C<Encode::LEAVE_SRC> is
#pod I<always> enforced.
#pod =cut

our $UTF8_CHECK = Encode::FB_CROAK | Encode::LEAVE_SRC; # Die on encoding errors

# UTF-8 Encoding object
my $_UTF8 = Encode::find_encoding('UTF-8');

sub import {
    # If run on the dos/os2/windows platform, ignore overriding functions silently.
    # These platforms do not have (proper) utf-8 file system suppport...
    unless ($^O =~ /MSWin32|cygwin|dos|os2/) {
        no strict qw(refs); ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no warnings qw(redefine);

        # Redefine each of the functions to their UTF-8 equivalent
        for my $f (@{$original_package . '::EXPORT'}, @{$original_package . '::EXPORT_OK'}) {
            # If we already have the _orig_function, we have redefined the function
            # in an earlier load of this module, so we need not do it again
            unless ($_orig_functions{$f}) {
                $_orig_functions{$f} = \&{$original_package . '::' . $f};
                *{$original_package . '::' . $f} = \&{"_utf8_$f"};
            }
        }
        $^H{$current_package} = 1; # Set compiler hint that we should use the utf-8 version
    }

    # Determine symbols to export
    shift; # First argument contains the package (that's us)
    @_ = (':DEFAULT') if !@_; # If nothing provided, use default
    @_ = grep { $_ ne ':none' } @_; # Strip :none tag

    # Use exporter to export
    require Exporter;
    if (@_) {
        @_ = ($original_package, @_);
        goto &Exporter::import;
    }

    return;
}

sub unimport { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    $^H{$current_package} = 0; # Set compiler hint that we should not use the utf-8 version
    return;
}

sub _utf8_find {
    my $ref = shift; # This can be the wanted function or a find options hash
    #  Make argument always into the find's options hash
    my %find_options_hash = ref($ref) eq "HASH" ? %$ref : (wanted => $ref);

    # Holds the (possibly encoded) arguments
    my @args = @_;

    # Get the hint from the caller (one level deeper if called from finddepth)
    my $hints = ((caller 1)[3]//'') ne 'File::Find::utf8::_utf8_finddepth' ? (caller 0)[10] : (caller 1)[10];
    if ($hints->{$current_package}) {
        $UTF8_CHECK |= Encode::LEAVE_SRC if $UTF8_CHECK; # Enforce LEAVE_SRC

        # Save original processors
        my %org_proc;
        for my $proc ("wanted", "preprocess", "postprocess") { $org_proc{$proc} = $find_options_hash{$proc}; }
        my $follow_option = (exists $find_options_hash{follow} && $find_options_hash{follow})
            || (exists $find_options_hash{follow_fast} && $find_options_hash{follow_fast});

        # Wrap processors to become utf8-aware
        if (defined $org_proc{wanted} && ref $org_proc{wanted}) {
            $find_options_hash{wanted} = sub {
                # Decode the file variables so they become characters
                local $_                    = $_UTF8->decode($_,                    $UTF8_CHECK) if $_;
                local $File::Find::name     = $_UTF8->decode($File::Find::name,     $UTF8_CHECK) if $File::Find::name;
                local $File::Find::dir      = $_UTF8->decode($File::Find::dir,      $UTF8_CHECK) if $File::Find::dir;
                local $File::Find::fullname = $_UTF8->decode($File::Find::fullname, $UTF8_CHECK) if $follow_option && $File::Find::fullname;
                # These are only necessary for compatibility reasons (find.pl, find2perl).
                # If you need them, set $File::Find::utf8::SPECIALVARS
                local $File::Find::topdir   = $_UTF8->decode($File::Find::topdir,   $UTF8_CHECK) if $SPECIALVARS && $File::Find::topdir;
                local $File::Find::topdev   = $_UTF8->decode($File::Find::topdev,   $UTF8_CHECK) if $SPECIALVARS && $File::Find::topdev;
                local $File::Find::topino   = $_UTF8->decode($File::Find::topino,   $UTF8_CHECK) if $SPECIALVARS && $File::Find::topino;
                local $File::Find::topmode  = $_UTF8->decode($File::Find::topmode,  $UTF8_CHECK) if $SPECIALVARS && $File::Find::topmode;
                local $File::Find::topnlink = $_UTF8->decode($File::Find::topnlink, $UTF8_CHECK) if $SPECIALVARS && $File::Find::topnlink;
                return $org_proc{wanted}->(map { $_ ? $_UTF8->decode($_, $UTF8_CHECK) : $_ } @_);
            };
        }
        for my $proc ("preprocess", "postprocess") {
            if (defined $org_proc{$proc} && ref $org_proc{$proc}) {
                $find_options_hash{$proc} = sub {
                    # Decode the file variables so they become characters
                    local $File::Find::dir = $_UTF8->decode($File::Find::dir, $UTF8_CHECK) if $File::Find::dir;
                    # Decode the arguments and encode the results
                    return map { $_ ? $_UTF8->encode($_, $UTF8_CHECK) : $_ } $org_proc{$proc}->(map { $_ ? $_UTF8->decode($_, $UTF8_CHECK) : $_ } @_);
                };
            }
        }
        # Encode arguments as utf-8 so that the original File::Find receives bytes
        @args = map { $_ ? $_UTF8->encode($_, $UTF8_CHECK) : $_ } @_;
    }

    # Make sure warning level propagates to File::Find
    # Note: on perl prior to v5.12 warnings_fatal_enabled does not exist
    #       so we can not use it.
    if (!warnings::enabled('File::Find')) {
        no warnings 'File::Find';
        return $_orig_functions{find}->(\%find_options_hash, @args);
    } elsif (!exists &warnings::fatal_enabled or !warnings::fatal_enabled('File::Find')) {
        use warnings 'File::Find';
        return $_orig_functions{find}->(\%find_options_hash, @args);
    } else {
        use warnings FATAL => qw(File::Find);
        return $_orig_functions{find}->(\%find_options_hash, @args);
    }
}

sub _utf8_finddepth {
    my $ref = shift; # This can be the wanted function or a find options hash
    return _utf8_find( { bydepth => 1, ref($ref) eq "HASH" ? %$ref : (wanted => $ref) }, @_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Find::utf8 - Fully UTF-8 aware File::Find

=head1 VERSION

version 0.014

=for test_synopsis my @directories_to_search;

=head1 SYNOPSIS

    # Use the utf-8 versions of find and finddepth
    use File::Find::utf8;
    find(\&wanted, @directories_to_search);

    # Revert back to non-utf-8 versions
    no File::Find::utf8;
    finddepth(\&wanted, @directories_to_search);

    # Export only the find function
    use File::Find::utf8 qw(find);
    find(\&wanted, @directories_to_search);

    # Export no functions
    use File::Find::utf8 qw(:none); # NOT "use File::Find::utf8 qw();"!
    File::Find::find(\&wanted, @directories_to_search);

=head1 DESCRIPTION

While the original L<File::Find> functions are capable of handling
UTF-8 quite well, they expect and return all data as bytes, not as
characters.

This module replaces the L<File::Find> functions with fully UTF-8
aware versions, both expecting and returning characters.

B<Note:> Replacement of functions is not done on DOS, Windows, and OS/2
as these systems do not have full UTF-8 file system support.

=head2 Behaviour

The module behaves as a pragma so you can use both C<use
File::Find::utf8> and C<no File::Find::utf8> to turn utf-8 support on
or off.

By default, both find() and finddepth() are exported (as with the original
L<File::Find>), if you want to prevent this, use C<use File::Find::utf8
qw(:none)>. (As all the magic happens in the module's import function,
you can not simply use C<use File::Find::utf8 qw()>)

L<File::Find> warning levels are properly propagated. Note though that
for propagation of fatal L<File::Find> warnings, Perl 5.12 or higher
is required (or the appropriate version of L<warnings>).

=head1 ATTRIBUTES

=head2 $File::Find::utf8::SPECIALVARS

By default C<File::Find::utf8> only decodes the I<normal>
L<File::Find> variables C<$_>, C<$File::Find::name>,
C<$File::Find::dir>, and (when C<follow> or C<follow_fast> is in
effect) C<$File::Find::fullname> for use in the C<preprocess>,
C<wanted>, and C<postporcess> functions.

If for any reason (e.g., compatibility with find.pl or find2perl) you
also need the I<special> variables C<$File::Find::topdir>,
C<$File::Find::topdev>, C<$File::Find::topino>,
C<$File::Find::topmode>, and C<$File::Find::topnlink> to be decoded,
specify C<local $File::Find::utf8::COMPATILBILITY = 1;> in your
code. The extra decoding that needs to happen will impact performance
though, so use only when absolutely necessary.

=head2 $File::Find::utf8::UTF8_CHECK

By default C<File::Find::utf8> marks decoding errors as fatal (default value
for this setting is C<Encode::FB_CROAK>). If you want, you can change this by
setting C<File::Find::utf8::UTF8_CHECK>. The value C<Encode::FB_WARN> reports
the encoding errors as warnings, and C<Encode::FB_DEFAULT> will completely
ignore them. Please see L<Encode> for details. Note: C<Encode::LEAVE_SRC> is
I<always> enforced.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker
L<website|https://github.com/HayoBaan/File-Find-utf8/issues>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COMPATIBILITY

The filesystems of Dos, Windows, and OS/2 do not (fully) support
UTF-8. The L<File::Find> function will therefore not be replaced on these
systems.

=head1 SEE ALSO

=over 4

=item *

L<File::Find> -- The original module.

=item *

L<Cwd::utf8> -- Fully utf-8 aware version of the L<Cwd> functions.

=item *

L<utf8::all> -- Turn on utf-8, all of it. This was also the module I first added the utf-8 aware versions of L<Cwd> and L<File::Find> to before moving them to their own package.

=back

=head1 AUTHOR

Hayo Baan <info@hayobaan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Hayo Baan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
