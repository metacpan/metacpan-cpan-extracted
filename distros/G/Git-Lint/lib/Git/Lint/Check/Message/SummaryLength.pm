package Git::Lint::Check::Message::SummaryLength;

use strict;
use warnings;

use parent 'Git::Lint::Check::Message';

our $VERSION = '0.010';

use constant SUMMARY_LENGTH => 50;

my $check_name        = 'summary length';
my $check_description = SUMMARY_LENGTH . ' characters or less';

sub check {
    my $self  = shift;
    my $input = shift;

    my $match = sub {
        my $lines_arref = shift;
        my $summary     = shift @{$lines_arref};
        return 1 if length $summary > SUMMARY_LENGTH;
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

Git::Lint::Check::Message::SummaryLength - check summary length

=head1 SYNOPSIS

 my $plugin = Git::Lint::Check::Message::SummaryLength->new();

 my $input = $plugin->message( file => $filepath );
 my @lines = @{$input};
 my @issues = $plugin->check( \@lines );

=head1 DESCRIPTION

C<Git::Lint::Check::Message::SummaryLength> is a C<Git::Lint::Check::Message> module which checks git commit message input to ensure the summary line is 50 characters or less.

=head1 METHODS

=over

=item check

=back

=cut
