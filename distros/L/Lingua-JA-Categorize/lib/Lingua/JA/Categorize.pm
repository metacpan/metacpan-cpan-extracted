package Lingua::JA::Categorize;
use strict;
use warnings;
use Lingua::JA::Categorize::Tokenizer;
use Lingua::JA::Categorize::Categorizer;
use Lingua::JA::Categorize::Generator;
use base qw( Lingua::JA::Categorize::Base );

__PACKAGE__->mk_accessors($_) for qw( tokenizer categorizer generator );

our $VERSION = '0.02002';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->tokenizer(
        Lingua::JA::Categorize::Tokenizer->new( context => $self ) );
    $self->categorizer(
        Lingua::JA::Categorize::Categorizer->new( context => $self ) );
    $self->generator(
        Lingua::JA::Categorize::Generator->new( context => $self ) );
    return $self;
}

sub categorize {
    my $self           = shift;
    my $text           = shift;
	my $word_num       = shift;
    my $word_set       = $self->tokenizer->tokenize( \$text, $word_num );
    my $user_extention = $self->tokenizer->user_extention;
    my $result = $self->categorizer->categorize( $word_set, $user_extention );
    return $result;
}

sub generate {
    my $self       = shift;
    my $categories = shift;
    my $brain      = $self->categorizer->brain;
    $self->generator->generate( $categories, $brain );
}

sub load {
    my $self      = shift;
    my $save_file = shift;
    $self->categorizer->load($save_file);
}

sub save {
    my $self      = shift;
    my $save_file = shift;
    $self->categorizer->save($save_file);
}

sub train {
    my $self = shift;
    $self->categorizer->train(@_);
}

1;
__END__

=head1 NAME

Lingua::JA::Categorize - Naive Bayes Classifier for Japanese document.

=head1 SYNOPSIS

  use Lingua::JA::Categorize;

  # generate
  my $categorizer = Lingua::JA::Categorize->new;
  $categorizer->generate($category_conf);
  $categorizer->save('save_file');

  # categorize
  my $categorizer = Lingua::JA::Categorize->new;
  $categorizer->load('save_file');
  my $result = $categorizer->categorize($text);
  print Dumper $result->score;

=head1 DESCRIPTION

Lingua::JA::Categorize is a Naive Bayes classifier for Japanese document.

B<THIS MODULE IS IN ITS ALPHA QUALITY.>

=head1 METHODS

=head2 new

The constructor method.

=head2 categorize($text)

This method accepts $text, and returns Lingua::JA::Categorize::Result object.

=head2 train

Training method of bayesian filter. 

=head2 generate(config => \%configuration_data)

This generate primary data set from the category configuration.

=head2 load('filename')

Load the saved file (that is Storable).

=head2 save('filemname')

Save the data to filename (that is Storable).

=head2 tokenizer

Accessor method to Lingua::JA::Categorize::Tokenizer.

=head2 categorizer

Accessor method to Lingua::JA::Categorize::Categorizer.

=head2 generator

Accessor method to Lingua::JA::Categorize::Generator.

=head1 AUTHOR

takeshi miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
