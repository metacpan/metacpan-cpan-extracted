package File::chmod::Recursive;

#######################
# LOAD MODULES
#######################
use strict;
use warnings;
use Carp qw(croak carp);

use Cwd qw(abs_path);
use File::Find qw(find);
use File::chmod qw(chmod);

#######################
# VERSION
#######################
our $VERSION = '1.0.3';

#######################
# EXPORT
#######################
use base qw(Exporter);
our ( @EXPORT, @EXPORT_OK );

@EXPORT    = qw(chmod_recursive);
@EXPORT_OK = qw(chmod_recursive rchmod chmodr);

#######################
# CHMOD RECURSIVE
#######################
sub chmod_recursive {

    # Read Input
    my @in = @_;

    # Default mode
    my $mode = {
        files       => q(),
        dirs        => q(),
        match_dirs  => {},
        match_files => {},
        match       => {},
    };

    # Default _find_ settings
    my %find_settings = (
        follow   => 0,  # Do not Follow symlinks
        no_chdir => 1,  # Do not chdir
    );

    # Verbose mode
    my $verbose = 0;

    # Check Input
    my $dir;
    if ( ref $in[0] eq 'HASH' ) {

        # Usage chmod_recursive({}, $dir);

        # Get modes
        $mode->{files}       = $in[0]->{files}       || q();
        $mode->{dirs}        = $in[0]->{dirs}        || q();
        $mode->{match_files} = $in[0]->{match_files} || {};
        $mode->{match_dirs}  = $in[0]->{match_dirs}  || {};
        $mode->{match}       = $in[0]->{match}       || {};

        # Check for _find_ settings
        if ( $in[0]->{follow_symlinks} ) {
            $find_settings{follow}      = 1;  # Follow Symlinks
            $find_settings{follow_skip} = 2;  # Skip duplicates
        } ## end if ( $in[0]->{follow_symlinks...})
        if ( $in[0]->{depth_first} ) {
            $find_settings{bydepth} = 1;
        }

        # Verbose on/off
        $verbose = $in[0]->{verbose} || 0;

    } ## end if ( ref $in[0] eq 'HASH')

    else {

        # Usage chmod_recursive($mode, $dir);

        # Set modes
        $mode->{files} = $in[0];
        $mode->{dirs}  = $in[0];
    } ## end else [ if ( ref $in[0] eq 'HASH')]

    # Get directory
    $dir = $in[1] || croak "Directory not provided";
    $dir = abs_path($dir);
    croak "$dir is not a directory" unless -d $dir;

    # Run chmod
    my @updated;
    {

        # Turn off warnings for file find
        no warnings 'File::Find';

        # Turn off UMASK for File::chmod
        # See: https://github.com/xenoterracide/File-chmod/issues/5
        local $File::chmod::UMASK = 0;

        find(
            {
                %find_settings,
                wanted => sub {

                    # The main stuff

                    # Get full path
                    my $path = $File::Find::name;

                    if ( not -l $path ) { # Do not set permissions on symlinks

                        # Process files
                        if ( -f $path ) {

                            my $file_isa_match = 0;

                            # Process file Matches
                            foreach
                              my $match_re ( keys %{ $mode->{match_files} } )
                            {
                              next if $file_isa_match;
                              next unless ( $path =~ m{$match_re} );
                                $file_isa_match = 1;  # Done matching
                                if (
                                    chmod(
                                        $mode->{match_files}->{$match_re},
                                        $path
                                    )
                                  )
                                {
                                    push @updated, $path;
                                    warn "chmod_recursive: $path -> "
                                      . (
                                        sprintf "%#o",
                                        $mode->{match_files}->{$match_re}
                                      )
                                      . "\n"
                                      if $verbose;
                                } ## end if ( chmod( $mode->{match_files...}))
                            } ## end foreach my $match_re ( keys...)

                            # Process generic matches
                            foreach my $match_re ( keys %{ $mode->{match} } )
                            {
                              next if $file_isa_match;
                              next unless ( $path =~ m{$match_re} );
                                $file_isa_match = 1;
                                if (
                                    chmod(
                                        $mode->{match}->{$match_re},
                                        $path
                                    )
                                  )
                                {
                                    push @updated, $path;
                                    warn "chmod_recursive: $path -> "
                                      . (
                                        sprintf "%#o",
                                        $mode->{match}->{$match_re}
                                      )
                                      . "\n"
                                      if $verbose;
                                } ## end if ( chmod( $mode->{match...}))
                            } ## end foreach my $match_re ( keys...)

                            # Process non-matches
                            if (

                                # Skip processed
                                ( not $file_isa_match )

                                # And we're updating files
                                and ( $mode->{files} )

                                # And succesfully updated
                                and ( chmod( $mode->{files}, $path ) )
                              )
                            {
                                push @updated, $path;
                                warn "chmod_recursive: $path -> "
                                  . ( sprintf "%#o", $mode->{files} ) . "\n"
                                  if $verbose;
                            } ## end if ( ( not $file_isa_match...))
                        } ## end if ( -f $path )

                        # Process Dirs
                        elsif ( -d $path ) {

                            my $dir_isa_match = 0;

                            # Process Matches
                            foreach
                              my $match_re ( keys %{ $mode->{match_dirs} } )
                            {
                              next if $dir_isa_match;
                              next unless ( $path =~ m{$match_re} );
                                $dir_isa_match = 1;  # Done matching
                                if (
                                    chmod(
                                        $mode->{match_dirs}->{$match_re},
                                        $path
                                    )
                                  )
                                {
                                    push @updated, $path;
                                    warn "chmod_recursive: $path -> "
                                      . (
                                        sprintf "%#o",
                                        $mode->{match_dirs}->{$match_re}
                                      )
                                      . "\n"
                                      if $verbose;
                                } ## end if ( chmod( $mode->{match_dirs...}))
                            } ## end foreach my $match_re ( keys...)

                            # Process generic matches
                            foreach my $match_re ( keys %{ $mode->{match} } )
                            {
                              next if $dir_isa_match;
                              next unless ( $path =~ m{$match_re} );
                                $dir_isa_match = 1;  # Done matching
                                if (
                                    chmod(
                                        $mode->{match}->{$match_re},
                                        $path
                                    )
                                  )
                                {
                                    push @updated, $path;
                                    warn "chmod_recursive: $path -> "
                                      . (
                                        sprintf "%#o",
                                        $mode->{match}->{$match_re}
                                      )
                                      . "\n"
                                      if $verbose;
                                } ## end if ( chmod( $mode->{match...}))
                            } ## end foreach my $match_re ( keys...)

                            # Process non-matches
                            if (

                                # Skip processed
                                ( not $dir_isa_match )

                                # And we're updating files
                                and ( $mode->{dirs} )

                                # And succesfully updated
                                and ( chmod( $mode->{dirs}, $path ) )
                              )
                            {
                                push @updated, $path;
                                warn "chmod_recursive: $path -> "
                                  . ( sprintf "%#o", $mode->{dirs} ) . "\n"
                                  if $verbose;
                            } ## end if ( ( not $dir_isa_match...))
                        } ## end elsif ( -d $path )

                    } ## end if ( not -l $path )

                },
            },
            $dir
        );
    }

    # Done
  return scalar @updated;
} ## end sub chmod_recursive

#######################
# ALIASES
#######################
sub rchmod { return chmod_recursive(@_); }
sub chmodr { return chmod_recursive(@_); }

#######################
1;

__END__

#######################
# POD SECTION
#######################
=pod

=head1 NAME

File::chmod::Recursive - Run chmod recursively against directories

=head1 DESCRIPTION

Like L<File::chmod>, but recursive with selective permissions

=head1 SYNOPSIS

    use File::chmod::Recursive;  # Exports 'chmod_recursive' by default

    # Apply identical permissions to everything
    #   Similar to chmod -R
    chmod_recursive( 0755, '/path/to/directory' );

    # Apply permissions selectively
    chmod_recursive(
        {
            dirs  => 0755,       # Mode for directories
            files => 0644,       # Mode for files

            # Match both directories and files
            match => {
                qr/\.sh|\.pl/ => 0755,
                qr/\.gnupg/   => 0600,
            },

            # You can also match files or directories selectively
            match_dirs  => { qr/\/logs\//    => 0775, },
            match_files => { qr/\/bin\/\S+$/ => 0755, },
        },
        '/path/to/directory'
    );

=head1 FUNCTIONS

=over

=item chmod_recursive(MODE, $path)

=item chmod_recursive(\%options, $path)

This function accepts two parameters. The first is either a I<MODE> or
an I<options hashref>. The second is the directory to work on. It
returns the number of files successfully changed, similar to
L<chmod|http://perldoc.perl.org/functions/chmod.html>.

When using a I<hashref> for selective permissions, the following
options are valid -

    {
        dirs  => MODE,  # Default Mode for directories
        files => MODE,  # Default Mode for files

        # Match both directories and files
        match => { qr/<some condition>/ => MODE, },

        # Match files only
        match_files => { qr/<some condition>/ => MODE, },

        # Match directories only
        match_dirs => { qr/<some condition>/ => MODE, },

        # Follow symlinks. OFF by default
        follow_symlinks => 0,

        # Depth first tree walking. ON by default (default _find_ behavior)
        depth_first => 1,
    }

In all cases the I<MODE> is whatever L<File::chmod> accepts.

=item rchmod

=item chmodr

This is an alias for C<chmod_recursive> and is exported only on
request.

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at
L<https://github.com/mithun/perl-file-chmod-recursive/issues>.

=head1 SEE ALSO

-   L<File::chmod>

-   L<chmod|http://perldoc.perl.org/functions/chmod.html>

-   L<Perl Monks thread on recursive perl
chmod|http://www.perlmonks.org/?node_id=61745>

=head1 AUTHOR

Mithun Ayachit  C<< <mithun@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Mithun Ayachit C<< <mithun@cpan.org> >>. All rights
reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

=cut
