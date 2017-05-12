package Lingua::YALI::Builder;
# ABSTRACT: Constructs language models for language identification.

use strict;
use warnings;
use Moose;
use Carp;
use Lingua::YALI;
use Moose::Util::TypeConstraints;
use List::MoreUtils qw(uniq);
use POSIX;

our $VERSION = '0.015'; # VERSION


subtype 'PositiveInt',
      as 'Int',
      where { $_ > 0 },
      message { "The number you provided, $_, was not a positive number" };


# list of all n-gram sizes that will be used during training
has 'ngrams' => (
    is => 'ro',
    isa => 'ArrayRef[PositiveInt]',
    required => 1
    );

# the greatest n-gram size
# i.e. ngrams = [1, 2, 3]; _max_ngram = 3
has '_max_ngram' => (
    is => 'rw',
    isa => 'Int'
    );

# hash of all n-grams
# After procissing string 'ab' and n-grams set to [ 1, 2]:
# _dict => { 1 => { 'a' => 1, 'b' => 1}; 2 => { 'ab' => 1 } }
has '_dict' => (
    is => 'rw',
    isa => 'HashRef'
    );


sub BUILD
{
    my $self = shift;

    # keep only unique n-gram sizes
    my @unique = uniq( @{$self->{ngrams}} );
    my @sorted = sort { $a <=> $b } @unique;
    $self->{ngrams} = \@sorted;

    # select the greatest n-gram
    $self->{_max_ngram} = $sorted[-1];

    return;
}



sub get_ngrams
{
    my $self = shift;
    return $self->ngrams;
}


sub get_max_ngram
{
    my $self = shift;
    return $self->{_max_ngram};
}


sub train_file
{
    my ( $self, $file ) = @_;

    # parameter check
    if ( ! defined($file) ) {
        return;
    }

    my $fh = Lingua::YALI::_open($file);

    return $self->train_handle($fh);
}


sub train_string
{
    my ( $self, $string ) = @_;

    # parameter check
    if ( ! defined($string) ) {
        return;
    }

    open(my $fh, "<", \$string) or croak $!;

    my $result = $self->train_handle($fh);

    close($fh);

    return $result;
}


sub train_handle
{
    my ($self, $fh) = @_;

#    print STDERR "\nX\n" . (ref $fh) . "\nX\n";

    # parameter check
    if ( ! defined($fh) ) {
        return;
    } elsif ( ref $fh ne "GLOB" ) {
        croak("Expected file handler but " . (ref $fh) . " was used.");
    }

#    my $padding = $self->{_padding};
    my @ngrams = @{$self->ngrams};
    my $padding = "";
    my $subsub = "";
    my $sub = "";

    my $total_length = 0;

    while ( <$fh> ) {
        chomp;
        s/ +/ /g;
        s/^ +//g;
        s/ +$//g;
        if ( ! $_ ) {
            next;
        }

        $_ = $padding . $_ . $padding;

        {
            use bytes;

            my $act_length = bytes::length($_);
            $total_length += $act_length;

            for my $i (0 .. $act_length - $self->{_max_ngram}) {
                $sub = substr($_, $i, $self->{_max_ngram});
                for my $j (@ngrams) {
                    $subsub = bytes::substr($sub, 0, $j);
#                   if ( $subsub =~ /[[:digit:][:punct:]]/ ) {
#                       next;
#                   }

                    $self->{_dict}->{$j}{$subsub}++;
                    $self->{_dict}->{$j}{___total___}++;
                }
            }
        }
    }

    return $total_length;
}


sub store
{
    my ($self, $file, $ngram, $count) = @_;

    # parameter check
    if ( ! defined($file) ) {
        croak("parametr file has to be specified");
    }

#    if ( -f $file && ! -w $file ) {
#        croak("file $file has to be writeable");
#    }

    if ( ! defined($ngram) ) {
        croak("parametr ngram has to be specified");
    }

    if ( ! defined($self->{_dict}->{$ngram}) ) {
        croak("$ngram-grams were not counted.");
    }

    if ( ! defined($count) ) {
        $count = POSIX::INT_MAX;
    }

    if ( $count < 1 ) {
        croak("At least one n-gram has to be saved. Count was set to: $count");
    }

    if ( ! defined($self->{_dict}->{$self->get_max_ngram()}) ) {
        croak("No training data was used.");
    }

    # open file
    open(my $fhModel, ">:gzip:bytes", $file) or croak($!);

    # prints out n-gram size
    print $fhModel $ngram . "\n";

    # store n-grams
    my $i = 0;
    for my $k (sort {
                        $self->{_dict}->{$ngram}{$b} <=> $self->{_dict}->{$ngram}{$a}
                        ||
                        $a cmp $b
                    } keys %{$self->{_dict}->{$ngram}}) {
        print $fhModel "$k\t$self->{_dict}->{$ngram}{$k}\n";
        if ( ++$i > $count ) {
            last;
        }
    }


    close($fhModel);

    return ($i - 1);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::YALI::Builder - Constructs language models for language identification.

=head1 VERSION

version 0.015

=head1 SYNOPSIS

This modul creates models for L<Lingua::YALI::Identifier|Lingua::YALI::Identifier>.

If your texts are from specific domain you can achive better
results when your models will be trained on texts from the same domain.

Creating bigram and trigram models from a string.

    use Lingua::YALI::Builder;
    my $builder = Lingua::YALI::Builder->new(ngrams=>[2, 3]);
    $builder->train_string("aaaaa aaaa aaa aaa aaa aaaaa aa");
    $builder->train_string("aa aaaaaa aa aaaaa aaaaaa aaaaa");
    $builder->store("model_a.2_4.gz", 2, 4);
    $builder->store("model_a.2_all.gz", 2);
    $builder->store("model_a.3_all.gz", 3);
    $builder->store("model_a.4_all.gz", 4);
    # croaks because 4-grams were not trained

More examples is presented in L<Lingua::YALI::Examples|Lingua::YALI::Examples>.

=head1 METHODS

=head2 BUILD

    BUILD()

Constructs C<Builder>.

    my $builder = Lingua::YALI::Builder->new(ngrams=>[2, 3, 4]);

=head2 get_ngrams

    my \@ngrams = $builder->get_ngrams()

Returns all n-grams that will be used during training.

    my $builder = Lingua::YALI::Builder->new(ngrams=>[2, 3, 4, 2, 3]);
    my $ngrams = $builder->get_ngrams();
    print join(", ", @$ngrams) . "\n";
    # prints out 2, 3, 4

=head2 get_max_ngram

    my $max_ngram = $builder->get_max_ngram()

Returns the highest n-gram size that will be used during training.

    my $builder = Lingua::YALI::Builder->new(ngrams=>[2, 3, 4]);
    print $builder->get_max_ngram() . "\n";
    # prints out 4

=head2 train_file

    my $used_bytes = $builder->train_file($file)

Uses file C<$file> for training and returns the amount of bytes used.

=over

=item * It returns undef if C<$file> is undef.

=item * It croaks if the file C<$file> does not exist or is not readable.

=item * It returns the amount of bytes used for trainig otherwise.

=back

For more details look at method L</train_handle>.

=head2 train_string

    my $used_bytes = $builder->train_string($string)

Uses string C<$string> for training and returns the amount of bytes used.

=over

=item * It returns undef if C<$string> is undef.

=item * It returns the amount of bytes used for trainig otherwise.

=back

For more details look at method L</train_handle>.

=head2 train_handle

    my $used_bytes = $builder->train_handle($fh)

Uses file handle C<$fh> for training and returns the amount of bytes used.

=over

=item * It returns undef if C<$fh> is undef.

=item * It croaks if the C<$fh> is not file handle.

=item * It returns the amount of bytes used for trainig otherwise.

=back

=head2 store

    my $stored_count = $builder->store($file, $ngram, $count)

Stores trained model with at most C<$count> C<$ngram>-grams to file C<$file>.
If count is not specified all C<$ngram>-grams are stored.

=over

=item * It croaks if incorrect parameters are passed or it was not trained.

=item * It returns the amount of stored n-grams.

=back

=head1 SEE ALSO

=over

=item * Trained models are suitable for L<Lingua::YALI::Identifier|Lingua::YALI::Identifier>.

=item * There is also command line tool L<yali-builder|Lingua::YALI::yali-builder> with similar functionality.

=item * Source codes are available at L<https://github.com/martin-majlis/YALI>.

=back

=head1 AUTHOR

Martin Majlis <martin@majlis.cz>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Martin Majlis.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
