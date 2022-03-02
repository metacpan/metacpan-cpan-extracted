package Git::Lint::Check::Message::BlankLineAfterSummary;

use strict;
use warnings;

use parent 'Git::Lint::Check::Message';

our $VERSION = '0.012';

my $check_name        = 'blank line after summary';
my $check_description = 'first line must be followed by a blank line';

sub check {
    my $self  = shift;
    my $input = shift;

    my $match = sub {
        my $lines_arref = shift;

        my @stripped = grep { !/^#/ } @{$lines_arref};

        my $summary     = shift @stripped;
        my $second_line = shift @stripped;

        return 1 if $second_line;

        return;
    };

    return $self->parse(
        input => $input,
        match => $match,
        check => $check_name . ' (' . $check_description . ')',
    );
}

1;

__END__

=pod

=head1 NAME

Git::Lint::Check::Message::BlankLineAfterSummary - check for blank line after summary

=head1 SYNOPSIS

 my $plugin = Git::Lint::Check::Message::BlankLineAfterSummary->new();

 my $input = $plugin->message( file => $filepath );
 my @lines = @{$input};
 my @issues = $plugin->check( \@lines );

=head1 DESCRIPTION

C<Git::Lint::Check::Message::BlankLineAfterSummary> is a C<Git::Lint::Check::Message> module which checks git commit message input to ensure summary is followed by a blank line.

=head1 METHODS

=over

=item check

=back

=cut
