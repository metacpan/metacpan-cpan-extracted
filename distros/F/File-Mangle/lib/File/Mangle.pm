package File::Mangle;

use 5.008001;
use strict;
use warnings;

require Exporter;
require File::Slurp;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use File::Mangle ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(replace_block);

our $VERSION = '0.02';

sub fetch_block {
    my ($filename, $marker) = @_;

    my $data = File::Slurp::read_file($filename);

    my $start = _format_start_marker($marker);
    my $end = _format_end_marker($marker);

    return unless $data =~ m{ \Q$start\E }xms and $data =~ m{ \Q$end\E }xms;

    if ( $data =~ m{
        ^ .* \Q$start\E .* $   # start marker
        ((?s: .*? ))           # existing content
        ^ .* \Q$end\E .* $     # end marker
    }xm ) {
        return $1;
    }
    else {
        return;
    }
}

sub replace_block {
    my ($filename, $marker, $replacement, $line_comment_marker) = @_;

    $line_comment_marker ||= '#';
    $replacement ||= '';

    my $data = File::Slurp::read_file($filename);

    my $start = _format_start_marker($marker);
    my $end = _format_end_marker($marker);

    unless ( $data =~ /$start/ and $data =~ /$end/ ) {
        $data .= "\n$line_comment_marker $start\n$line_comment_marker $end\n";
    }

    chomp $replacement;

    $data =~ s{
        ^ ( .* \Q$start\E .* ) $   # start marker
        ((?s: .*? ))               # existing content
        ^ ( .* \Q$end\E .* ) $     # end marker
    }{$1\n$replacement\n$3\n}xm;

    File::Slurp::write_file($filename, $data);

    return $2;
}

sub insert_block_before {
    my ($filename, $marker, $placement, $line_comment_marker) = @_;

    $line_comment_marker ||= '#';

    my $data = File::Slurp::read_file($filename);

    my $start = _format_start_marker($marker);
    my $end = _format_end_marker($marker);

    return if $data =~ m{ \Q$start\E }xms and $data =~ m{ \Q$end\E }xms;

    if ( $data =~ m{
            (
                \A (?s: .* )
            )
            (
                ^ .* $placement .* $
                (?s: .* ) \z
            )
        }xm
    ) {
        $data = $1;
        $data .= $line_comment_marker . ' ' . $start . "\n";
        $data .= $line_comment_marker . ' ' . $end . "\n";
        $data .= $2;

        File::Slurp::write_file($filename, $data);

        return 1;
    }
    else {
        return;
    }
}

sub insert_block_after {
    my ($filename, $marker, $placement, $line_comment_marker) = @_;

    $line_comment_marker ||= '#';

    my $data = File::Slurp::read_file($filename);

    my $start = _format_start_marker($marker);
    my $end = _format_end_marker($marker);

    return if $data =~ m{ \Q$start\E }xms and $data =~ m{ \Q$end\E }xms;

    if ( $data =~ m{
            (
                \A (?s: .* )
                ^ .* $placement .* $
            )
            (
                (?s: .* ) \z
            )
        }xm
    ) {
        $data = $1;
        $data .= "\n" . $line_comment_marker . ' ' .  $start . "\n";
        $data .= $line_comment_marker . ' ' . $end . "\n";
        $data .= $2;

        File::Slurp::write_file($filename, $data);

        return 1;
    }
    else {
        return;
    }
}

sub _format_start_marker {
    my $marker = shift;
    return '###:START:' . $marker . ':###';
}
sub _format_end_marker {
    my $marker = shift;
    return '###:END:' . $marker . ':###';
}

1;
__END__

=head1 NAME

File::Mangle - Perl module for file manipulation

=head1 SYNOPSIS

  use File::Mangle qw(replace_block);

  replace_block('/etc/sudoers', 'automanaged', "martyn ALL=(ALL) ALL");

  my $data = fetch_block('/etc/sudoers', 'automanaged');

=head1 DESCRIPTION

A collection of utilities designed to make programmatic editing of configuration
files nice and simple.

=head1 EXPORT

None by default.

=head1 FUNCTIONS

=head2 fetch_block(I<filename>, I<marker>)

Performs the returning existing block part of the B<replace_block()> function
below without altering the file in any way.

=head2 replace_block(I<filename>, I<marker>, I<replacement>, I<line-comment-marker>)

Edits the file I<filename> adding start and end I<marker>s if they're not already there.
Once the markers are in place, it replaces everything between the markers with I<replacement>.

I<line-comment-marker> defaults to '#' (which is prefixed to the markers to
ensure they don't intefere with the purpose of the file).

This function returns the data that I<was> in the block prior to the replacement.

=head2 insert_block_before(I<filename>, I<marker>, I<placement>, I<line-comment-marker>)

Edits the file I<filename> adding start and end I<marker>s if they're not already there.

The placement parameter is a regexp fragment which File::Mangle uses to find a
line in the target file to insert the markers before

I<line-comment-marker> defaults to '#' (which is prefixed to the markers to
ensure they don't intefere with the purpose of the file).

This function returns nothing if the block already exists or it was unable to
find the placement regexp, and it returns 1 on success

=head2 insert_block_after(I<filename>, I<marker>, I<placement>, I<line-comment-marker>)

This function operates exactly like insert_block_before with the exception of
putting the markers after the placement match instead of before.

=head1 AUTHOR

Martyn Smith, E<lt>martyn@dollyfish.net.nzE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Martyn Smith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
