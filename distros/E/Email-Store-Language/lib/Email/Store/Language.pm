package Email::Store::Language;

use strict;
use warnings;

our $VERSION = '0.03';

use base qw( Email::Store::DBI );

our $OPTIONS = {};

=head1 NAME

Email::Store::Language - Add language identification to emails and lists

=head1 SYNOPSIS

Remember to create the database table:

    % make install
    % perl -MEmail::Store="..." -e 'Email::Store->setup'

And now:

    for( $mail->languages ) {
        print $_->language . "\n";
    }

or

    for( $list->languages ) {
        print $_->language . "\n";
    }

=head1 DESCRIPTION

This module will help you auto-identify the language of
your messages and lists. There are some options you can use
to help refine the process.

=head2 set_active_languages

This is a method from L<Lingua::Identify> that will let you
limit what languages your messages should be checked against.

    # limit to english and french
    use Lingua::Identify qw( set_active_languages );
    set_active_languages( qw( en fr ) );

=head2 $EMAIL::Store::Language::OPTIONS

This is a hashref of options that will be passed as the
first argument to C<langof()>. There is one exception:
the C<threshold> option. C<threshold> should be a number
(percentage) between 0 and 1. The default is 0.5.

    $Email::Store::Language::OPTIONS = { threshold => 0.35 };

In the above example, a threshold of 0.35 means that, for mail
language identification, if L<Lingua::Identify> claims to be 35%
sure that the message is a given language it will store that language.
If no languages are above the threshold, then the language of most
confidence will be used.

For list identification, it means that if 35% of the messages are
identified as being a given language, then it will store that language.
If no languages are above the threshold, then the language of most
confidence will be used.

=head1 SEE ALSO

=over 4 

=item * Email::Store

=item * Lingua::Identify

=back

=head1 AUTHOR

=over 4 

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

package Email::Store::Mail::Language;

use base qw( Email::Store::DBI );

use strict; 
use warnings;

use Email::Store::Mail;

__PACKAGE__->table( 'mail_language' );
__PACKAGE__->columns( All => qw( id mail language ) );
__PACKAGE__->columns( Primary => qw( id ) );
__PACKAGE__->has_a( mail => 'Email::Store::Mail' );

Email::Store::Mail->has_many( languages => 'Email::Store::Mail::Language' );

sub on_store_order { 81 }

sub on_store {
	my( $self, $mail ) = @_;

	$mail->calculate_language;

	for my $list ( $mail->lists ) {
		my $probability = 1 / scalar( $list->posts );
		$list->calculate_language if rand( 1 ) <= $probability;
	}
}

package Email::Store::Mail;

use Lingua::Identify qw( langof );

sub calculate_language {
	my $self      = shift;

	my %options   = %{ $Email::Store::Language::OPTIONS };
	my $thresh    = delete $options{ threshold } || '0.5';
	my %languages = langof( \%options, $self->simple->body );
	my @langs     = sort { $languages{ $b } <=> $languages{ $a } } keys %languages;

	push @langs, 'en' unless @langs;

	$_->delete for $self->languages;

	my $count = 0;
	for( keys %languages ) {
		next unless $languages{ $_ } >= $thresh;
		$count++;
		$self->add_to_languages( { language => $_ } );
	}
	unless( $count ) {
		$self->add_to_languages( { language => $langs[ 0 ] } );
	}
}

package Email::Store::List;

use strict;
use warnings;

sub calculate_language {
	my $self = shift;

	my %languages;
	my $total = 0;
	for my $post ( $self->posts ) {
		my @languages = $post->languages;
		next unless @languages;
		$languages{ $_->language }++ for @languages;
		$total++;
	}

	$_->delete for $self->languages;

	my $thresh = $Email::Store::Language::OPTIONS->{ threshold } || 0.5;
	my @langs  = sort { $languages{ $b } <=> $languages{ $a } } keys %languages;

	my $count = 0;
	for( @langs ) {
		next unless $languages { $_ } / $total >= $thresh;
		$count++;
		$self->add_to_languages( { language => $_ } );
	}
	unless( $count ) {
		$self->add_to_languages( { language => $langs[ 0 ] } );
	}
}

package Email::Store::List::Language;

use strict;
use warnings;

use base 'Email::Store::DBI';

use Email::Store::List;

__PACKAGE__->table( 'list_language' );
__PACKAGE__->columns( All => qw( id list language ) );
__PACKAGE__->columns( Primary => qw( id ) );
__PACKAGE__->has_a( list => 'Email::Store::List' );

Email::Store::List->has_many( languages => 'Email::Store::List::Language' );

package Email::Store::Language;

1;

__DATA__
CREATE TABLE IF NOT EXISTS mail_language (
    id       INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    mail     VARHCHAR(255) NOT NULL,
    language VARCHAR(10)
);
CREATE TABLE IF NOT EXISTS list_language (
    id       INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    list     VARCHAR(255) NOT NULL,
    language VARCHAR(10)
);
