package File::Rename::Options;

use strict;
BEGIN { eval { require warnings; warnings->import } }

use Getopt::Long ();

use vars qw($VERSION);
$VERSION = '1.10';

eval{ Getopt::Long::Configure qw(
      posix_default
      no_ignore_case
      no_require_order
    ); 1 } or do { require Carp; Carp::carp($@) };

sub GetOptions {
    my ($no_code) = @_;
    my @expression;
    my $fullpath = 1;
    Getopt::Long::GetOptions(
        '-v|verbose'    => \my $verbose,
        '-0|null'       => \my $null,
        '-n|nono'       => \my $nono,
        '-f|force'      => \my $force,
        '-h|?|help'     => \my $help,
        '-m|man'        => \my $man,
        '-V|version'    => \my $version,
        '-d|filename'   => sub { undef $fullpath },
        '-path|fullpath!' => \$fullpath,
        '-e=s'          => \@expression,
        '-E=s' =>
            sub {
                my(undef, $e) = @_;
                $e .= ';';
                push @expression, $e;
            },
        '-u|unicode:s'  => \my $unicode,
      ) or return;

    my $options = {
        verbose         => $verbose,
        input_null      => $null,
        no_action       => $nono,
        over_write      => $force,
        filename_only   => !$fullpath,
        show_help       => $help,
        show_manual     => $man,
        show_version    => $version,
        unicode_strings => defined $unicode,
        encoding        => $unicode,
    };
    return $options if $no_code;
    return $options if $help or $man or $version;

    if( @expression ) {
        $options->{_code} = join "\n", @expression;
    }
    else {
        return unless @ARGV;
        $options->{_code} = shift @ARGV;
    }
    return $options;
}

sub bad_encoding {
    my $options = shift;
    my $encoding = $options->{encoding};
    return unless $encoding;
    return unless $encoding =~ /[^\s\w.-]/;
    return 1
} 

1;
__END__

=head1 NAME

File::Rename::Options - Option processing for File::Rename

=head1 SYNOPSIS

    use File::Rename::Options;
    my $options = File::Rename::Options::GetOptions()
        or pod2usage;

=head1 DESCRIPTION

=over 4

=item C<GetOptions()>

Call C<Getopt::Long::GetOptions()> with options for rename script,
returning a HASH of options.

=item C<bad_encoding($options)>

Test if I<encoding> does not look like an encoding

=back

=head2 OPTIONS

See L<rename> script for options (in C<@ARGV>).

See L<File::Rename> for structure of the options HASH

=head1 ENVIRONMENT

No environment variables are used.

=head1 SEE ALSO

File::Rename(3), rename(1)

=head1 AUTHOR

Robin Barker <RMBarker@cpan.org>

=head1 DIAGNOSTICS

Returns C<undef> when there is an error in the options.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Robin Barker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


