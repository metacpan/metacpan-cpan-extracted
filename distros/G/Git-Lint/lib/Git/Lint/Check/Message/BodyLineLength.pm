package Git::Lint::Check::Message::BodyLineLength;

use strict;
use warnings;

use parent 'Git::Lint::Check::Message';

our $VERSION = '0.012';

use constant BODY_LENGTH => 68;

my $check_name        = 'body line length';
my $check_description = BODY_LENGTH . ' characters or less';

sub check {
    my $self  = shift;
    my $input = shift;

    my $match = sub {
        my $lines_arref = shift;
        my $summary     = shift @{$lines_arref};

        foreach my $line ( @{$lines_arref} ) {
            return 1 if length $line > BODY_LENGTH;
        }

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

Git::Lint::Check::Message::BodyLineLength - check body line length

=head1 SYNOPSIS

 my $plugin = Git::Lint::Check::Message::BodyLineLength->new();

 my $input = $plugin->message( file => $filepath );
 my @lines = @{$input};
 my @issues = $plugin->check( \@lines );

=head1 DESCRIPTION

C<Git::Lint::Check::Message::BodyLineLength> is a C<Git::Lint::Check::Message> module which checks git commit message input to ensure each line of the body is 68 characters or less.

=head1 METHODS

=over

=item check

=back

=cut
