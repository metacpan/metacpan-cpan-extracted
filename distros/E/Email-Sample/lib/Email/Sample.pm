package Email::Sample;

use warnings;
use strict;
use Data::Random qw(:all);
# use Text::Greeking;


=head1 NAME

Email::Sample - generate sample email for testing

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Email::Sample;

    my $emailgen = Email::Sample->new();
    ...

    $emailgen->add_valid_domains( [ 'url.com.tw'  , 'google2.com.tw'  ] );

    my @valid_emails = $emailgen->valid_emails( size => 20 );

    my @invalid_emails = $emailgen->invalid_emails();

=head1 DESCRIPTION

Email::Sample use L<Data::Random> to generate a bunch of valid or invalid email
for testing.

=head1 FUNCTIONS

=cut

sub new {
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}

=head2 valid_emails

=cut

my @valid_domains = qw(
    yahoo.com
    gmail.com
);

sub valid_emails {
    my $self = shift;
    my %args = @_;

    $args{size} ||= 10;
    my @emails = ();
    for( 1 .. $args{size} ) {
        push @emails, $self->g_valid_identity() . '@' . $self->get_random_valid_domain;
    }
    return \@emails;
}

sub add_domains {
    my $self = shift;
    $self->add_valid_domains(@_);
}

=head2 add_valid_domains (ARRAY)

=cut

sub add_valid_domains {
    my $class = shift;
    push @valid_domains , @_;
}

sub add_invalid_domains {

}

sub get_random_valid_domain {
    return $valid_domains[ 
        int( rand( scalar(@valid_domains) - 1 ) )
    ];
}

sub g_valid_identity {
    my $self = shift;
    my %args = @_;
    $args{seperator} ||= '_';
    my @random_words = rand_words( size => 3 );
    return join( $args{seperator} , @random_words );
}

sub g_invalid_identity {
    my ($self, %args ) = @_;

}



=head1 AUTHOR

Cornelius, C<< <cornelius.howl at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-email-sample at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Sample>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::Sample


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Sample>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-Sample>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-Sample>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-Sample/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Cornelius, all rights reserved.

This program is released under the following license: MIT


=cut

1; # End of Email::Sample
