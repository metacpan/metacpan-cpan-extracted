package Git::Repository::Plugin::Diff::Hunk;

use warnings;
use strict;

use Carp qw/croak/;

sub new {
    my ( $pkg, %args ) = @_;
    my $from_line_start = delete $args{from_line_start};
    my $from_line_count = delete $args{from_line_count};
    my $to_line_start   = delete $args{to_line_start};
    my $to_line_count   = delete $args{to_line_count};
    my $header          = delete $args{_header};

    return bless {
        _header => $header,

        from_line_start    => $from_line_start,
        from_line_count    => $from_line_count,
        from_lines         => [],
        _from_line_counter => $from_line_start,

        to_line_start    => $to_line_start,
        to_line_count    => $to_line_count,
        _to_line_counter => $to_line_start,

        to_lines => [],

    }, $pkg;
}

# @@ -5,3 +5,5 @@
# @@ -0,0 +1 @@
# @@ -1,7 +0,0 @@
# @@ -1,7 +1 @@

sub parse_header {
    my ( $pkg, $str ) = @_;

    my ( $from_file_line_numbers, $to_file_line_numbers ) =
      $str =~ /^\@\@ \s \-(\S+) \s \+(\S+) \s \@\@/x;

    croak "Cant parse hunk header: $str"
      if !defined $from_file_line_numbers || !defined $to_file_line_numbers;

    my ( $from_line_start, $from_line_count ) =
      $pkg->_parse_hunk_numbers($from_file_line_numbers);

    my ( $to_line_start, $to_line_count ) =
      $pkg->_parse_hunk_numbers($to_file_line_numbers);

    return $pkg->new(
        _header => $str,

        from_line_start => $from_line_start,
        from_line_count => $from_line_count,

        to_line_start => $to_line_start,
        to_line_count => $to_line_count,
    );
}

sub to_line_start {
    my ($self) = @_;
    return $self->{to_line_start};
}

sub to_line_count {
    my ($self) = @_;
    return $self->{to_line_count};
}

sub from_line_start {
    my ($self) = @_;
    return $self->{from_line_start};
}

sub from_line_count {
    my ($self) = @_;
    return $self->{from_line_count};
}

sub _parse_hunk_numbers {
    my ( $pkg, $numbers_str ) = @_;
    my ( $line_start, $line_count ) = split ',', $numbers_str;
    $line_count //= 1;
    return $line_start, $line_count;
}

sub add_line {
    my ( $self, $line ) = @_;

    my $diff_char = substr $line, 0, 1, "";

    if ( $diff_char eq ' ' ) {
        $self->{_to_line_counter}   += 1;
        $self->{_from_line_counter} += 1;
        return 1;
    }
    elsif ( $diff_char eq '+' ) {
        $self->process_to_line($line);
    }
    elsif ( $diff_char eq '-' ) {
        $self->process_from_line($line);
    }
    elsif ( $diff_char eq '\\' ) {
        return 1;
    }
    else {
        croak "Malformed diff line: '$line'";
    }

    return 1;
}

sub process_from_line {
    my ( $self, $line ) = @_;
    return $self->_process_line( "from", $line );
}

sub process_to_line {
    my ( $self, $line ) = @_;
    return $self->_process_line( "to", $line );
}

sub _process_line {
    my ( $self, $kind, $line ) = @_;

    croak "${kind} is unknown line type!"
      if $kind ne 'to' && $kind ne 'from';

    my $lines_key        = "${kind}_lines";
    my $line_counter_key = "_${kind}_line_counter";

    push @{ $self->{$lines_key} }, [ $self->{$line_counter_key}, $line ];

    $self->{$line_counter_key} += 1;

    return;
}

sub from_lines {
    my ($self) = @_;
    return @{ $self->{from_lines} };
}

sub to_lines {
    my ($self) = @_;
    return @{ $self->{to_lines} };
}

1;

__END__

=encoding utf-8

=head1 NAME

Git::Repository::Plugin::Diff::Hunk - object that contains diff lines.
L<About diff format|https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html#Detailed-Unified>

=head1 SYNOPSIS

    # Load the plugin.
    use Git::Repository 'Diff';

    my $repository = Git::Repository->new();

    # Get the git diff information.
    my $file_diff = $repository->diff( $file, "HEAD", "HEAD~1" );
    my $other_file_diff = $repository->diff( $file, "HEAD", "origin/master" );

    my @hunks = $file_diff->get_hunks;

    my $first_hunk = shift @hunks;
    _dump_diff($first_hunk);

    sub _dump_diff {
        my ($hunk) = @_;
        for my $l ($first_hunk->to_lines) {
            my ($line_num, $line_content) = @$l;
            print("+ $line_num: $line_content\n")
        }
        for my $l ($first_hunk->from_lines) {
            my ($line_num, $line_content) = @$l;
            print("- $line_num: $line_content\n")
        }
    }

=head1 DESCRIPTION


=head2 from_lines
=head2 to_lines

Returns a list of arrays for each line for to/from file diff.
The first array element is line number. The second is line content.

=head2 to_line_start
=head2 from_line_start

The first number in hunk header

=head2 from_line_count
=head2 to_line_count

The second number in hunk header

=head1 AUTHOR

d.tarasov E<lt>d.tarasov@corp.mail.ruE<gt>

=head1 COPYRIGHT

Copyright 2020- d.tarasov

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
