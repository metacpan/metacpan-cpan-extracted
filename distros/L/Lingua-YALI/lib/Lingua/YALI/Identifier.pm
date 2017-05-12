package Lingua::YALI::Identifier;
# ABSTRACT: Module for language identification with custom models.

use strict;
use warnings;
use Moose;
use Carp;
use PerlIO::gzip;
use Lingua::YALI;

our $VERSION = '0.015'; # VERSION

# hash with paths to models
# format: { 'class1' => 'file1', 'class2' => 'file2' }
has '_model_file' => (
    is => 'rw',
    isa => 'HashRef'
    );

# hash with n-gram frequencies retrieved from models
# format: { 'ngram1' => { 'class1' => 0.5, 'class2' => 0.3}, 'ngram2' => ...}
has '_frequency' => (
    is => 'rw',
    isa => 'HashRef'
    );

# n-gram size
has '_ngram' => (
    is => 'rw',
    isa => 'Int'
    );

# list of identified classes
has '_classes' =>  (
    is => 'rw',
    isa => 'ArrayRef'
    );



sub BUILD
{
    my $self = shift;
    my %frequency = ();
    my @classes = ();
    $self->{_frequency} = \%frequency;
    $self->{_classes} = \@classes;

    return;
}


sub add_class
{
    my ( $self, $class, $file ) = @_;

    if ( defined( $self->{_model_file}->{$class} ) ) {
        return 0;
    }

    # parameter check
    if ( ! defined($file) ) {
        croak("Model has to be specified.");
    }

    if ( ! -r $file ) {
        croak("Model $file is not readable.");
    }

    $self->_load_model($class, $file);

    return 1;
}


sub remove_class
{
    my ( $self, $class ) = @_;

    if ( defined( $self->{_model_file}->{$class} ) ) {
        $self->_unload_model($class);

        return 1;
    }

    return 0;
}


sub get_classes
{
    my $self    = shift;
    return $self->{_classes};
}


sub identify_file
{
    my ( $self, $file ) = @_;

    if ( ! defined($file) ) {
        return;
    }

    my $fh = Lingua::YALI::_open($file);

    return $self->identify_handle($fh);
}


sub identify_string
{
    my ( $self, $string ) = @_;
    open(my $fh, "<", \$string) or croak $!;

    if ( ! defined($string) ) {
        return;
    }

    my $result = $self->identify_handle($fh);

    close($fh);

    return $result;
}


sub identify_handle
{
    my ($self, $fh) = @_;
    my %actRes = ();

    # parameter check
    my $ngram = $self->{_ngram};
    if ( ! defined($ngram) ) {
        croak("At least one class must be specified.");
    }

    if ( ! defined($fh) ) {
        return;
    } elsif ( ref $fh ne "GLOB" ) {
        croak("Expected file handler but " . (ref $fh) . " was used.");
    }

    # read input file
    while ( <$fh> ) {
        chomp;
        s/ +/ /g;
        s/^ +//g;
        s/ +$//g;
        if ( ! $_ ) {
            next;
        }

#        $_ = $padding . $_ . $padding;

        {
            use bytes;
            for my $i (0 .. bytes::length($_) - $ngram) {
                my $w = substr($_, $i, $ngram);

                if ( defined($self->{_frequency}->{$w}) ) {
                    for my $lang (keys %{$self->{_frequency}->{$w}}) {
#                       print STDERR "$w - $lang - $frequency{$w}{$lang}\n";
                        $actRes{$lang} += $self->{_frequency}->{$w}{$lang};
#                       print STDERR "Lang: $lang - $actRes{$lang}\n";
                    }
                }
            }
        }
    }

    # sum scores of all classifiers
    my @allLanguages = @ { $self->get_classes() };

    my $sum = 0;
    for my $l (@allLanguages) {
        my $score = 0;
        if ( defined($actRes{$l}) ) {
            $score = $actRes{$l};
        }
        $sum += $score;
    }

    # normalize results
    my @res = ();

    for my $l (@allLanguages) {
        my $score = 0;
        if ( defined($actRes{$l}) ) {
            $score = $actRes{$l} / $sum;
        }
        my @pair = ($l, $score);
        push(@res, \@pair);
    }

    # sort according to score
    my @sortedRes = sort { $b->[1] <=> $a->[1] } @res;

    return \@sortedRes;
}

# recompute classes after manipulation with classes
sub _compute_classes
{
    my $self    = shift;
    my @classes = keys %{ $self->{_model_file} };

    $self->{_classes} = \@classes;

    return;
}

# load model
sub _load_model
{
    my ($self, $class, $file) = @_;

    if ( $self->{_model_file}->{$class} ) {
        return;
    }

    open(my $fh, "<:gzip:bytes", $file) or croak($!);
    my $ngram = <$fh>;
    my $total_line = <$fh>;

    if ( ! defined($self->{_ngram}) ) {
        $self->{_ngram} = $ngram;
    } else {
        if ( $ngram != $self->{_ngram} ) {
            croak("Incompatible model for '$class'. Expected $self->{_ngram}-grams, but was $ngram-gram.");
        }
    }

    my $sum = 0;
    while ( <$fh> ) {
        chomp;
        my @p = split(/\t/, $_);
        my $word = $p[0];
        $self->{_frequency}->{$word}{$class} = $p[1];
        $sum += $p[1];
    }

    for my $word (keys %{$self->{_frequency}}) {
        if ( defined($self->{_frequency}->{$word}{$class}) ) {
            $self->{_frequency}->{$word}{$class} /= $sum;
        }
    }

    close($fh);

    $self->{_model_file}->{$class} = $file;
    $self->_compute_classes();

    return;
}

# unload model
sub _unload_model
{
    my ($self, $class) = @_;

    if ( ! $self->{_model_file}->{$class} ) {
        return;
    }

    delete( $self->{_model_file}->{$class} );
    $self->_compute_classes();

    my $classes = $self->get_classes();
#    print STDERR "\nX=removing $class\n" . (join("\t", @$classes)) . "\n" . (scalar @$classes) . "\nX\n";
    if ( scalar @$classes == 0 ) {
        delete($self->{_ngram});
        $self->{_ngram} = undef;
    }




    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::YALI::Identifier - Module for language identification with custom models.

=head1 VERSION

version 0.015

=head1 SYNOPSIS

This modul identify languages with moduls provided by the user. If you want to use pretrained models use L<Lingua::YALI::LanguageIdentifier|Lingua::YALI::LanguageIdentifier>.

Models trained on texts from specific domain outperforms the general ones.

    use Lingua::YALI::Builder;
    use Lingua::YALI::Identifier;

    # create models
    my $builder_a = Lingua::YALI::Builder->new(ngrams=>[2]);
    $builder_a->train_string("aaaaa aaaa aaa aaa aaa aaaaa aa");
    $builder_a->store("model_a.2_all.gz", 2);

    my $builder_b = Lingua::YALI::Builder->new(ngrams=>[2]);
    $builder_b->train_string("bbbbbb bbbb bbbb bbb bbbb bbbb bbb");
    $builder_b->store("model_b.2_all.gz", 2);

    # create identifier and load models
    my $identifier = Lingua::YALI::Identifier->new();
    $identifier->add_class("a", "model_a.2_all.gz");
    $identifier->add_class("b", "model_b.2_all.gz");

    # identify strings
    my $result1 = $identifier->identify_string("aaaaaaaaaaaaaaaaaaa");
    print $result1->[0]->[0] . "\t" . $result1->[0]->[1];
    # prints out a 1

    my $result2 = $identifier->identify_string("bbbbbbbbbbbbbbbbbbb");
    print $result2->[0]->[0] . "\t" . $result2->[0]->[1];
    # prints out b 1

More examples is presented in L<Lingua::YALI::Examples|Lingua::YALI::Examples>.

=head1 METHODS

=head2 BUILD

Initializes internal variables.

    # create identifier
    my $identifier = Lingua::YALI::Identifier->new();

=head2 add_class

    $added = $identifier->add_class($class, $model)

Adds model stored in file C<$model> with class C<$class> and
returns whether it was added or not.

    print $identifier->add_class("a", "model.a1.gz") . "\n";
    # prints out 1
    print $identifier->add_class("a", "model.a2.gz") . "\n";
    # prints out 0 - class a was already added

=head2 remove_class

     my $removed = $identifier->remove_class($class);

Removes model for class C<$class>.

    $identifier->add_class("a", "model.a1.gz");
    print $identifier->remove_class("a") . "\n";
    # prints out 1
    print $identifier->remove_class("a") . "\n";
    # prints out 0 - class a was already removed

=head2 get_classes

    my \@classes = $identifier->get_classes();

Returns all registered classes.

=head2 identify_file

    my $result = $identifier->identify_file($file)

Identifies class for file C<$file>.

=over

=item * It returns undef if C<$file> is undef.

=item * It croaks if the file C<$file> does not exist or is not readable.

=item * Otherwise look for more details at method L</identify_handle>.

=back

=head2 identify_string

    my $result = $identifier->identify_string($string)

Identifies class for string C<$string>.

=over

=item * It returns undef if C<$string> is undef.

=item * Otherwise look for more details at method L</identify_handle>.

=back

=head2 identify_handle

    my $result = $identifier->identify_handle($fh)

Identifies class for file handle C<$fh> and returns:

=over

=item * It returns undef if C<$fh> is undef.

=item * It croaks if the C<$fh> is not file handle.

=item * It returns array reference in format [ ['class1', score1], ['class2', score2], ...] sorted
according to score descendently, so the most probable class is the first.

=back

=head1 SEE ALSO

=over

=item * Identifier with pretrained models for language identification is L<Lingua::YALI::LanguageIdentifier|Lingua::YALI::LanguageIdentifier>.

=item * Builder for these models is L<Lingua::YALI::Builder|Lingua::YALI::Builder>.

=item * There is also command line tool L<yali-identifier|Lingua::YALI::yali-identifier> with similar functionality.

=item * Source codes are available at L<https://github.com/martin-majlis/YALI>.

=back

=head1 AUTHOR

Martin Majlis <martin@majlis.cz>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Martin Majlis.

This is free software, licensed under:

  The (three-clause) BSD License

=head1 AUTHOR

Martin Majlis <martin@majlis.cz>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Martin Majlis.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
