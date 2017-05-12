# ABSTRACT: Faker Standard Lorem Provider
package Faker::Provider::Lorem;

use Faker::Base;

extends 'Faker::Provider';

our $VERSION = '0.12'; # VERSION

method paragraph (INTEGER :$n_sentences = 4) {
    return $self->sentences(n_sentences => $n_sentences) . "\n\n";
}

method paragraphs (INTEGER :$n_paragraphs = 2, INTEGER :$v_length = 5) {
    return join "", map {
        $v_length > 4 ?
            $self->paragraph(n_sentences => $self->random_between(4, $v_length)) :
            $self->paragraph
    }   1..$n_paragraphs;
}

method sentence (INTEGER :$n_words = 5) {
    return $self->words(count => $n_words) . '.';
}

method sentences (INTEGER :$n_paragraphs = 3, INTEGER :$v_length = 10) {
    return join ' ', map {
        $v_length > 3 ?
            $self->sentence(n_words => $self->random_between(3, $v_length)) :
            $self->sentence
    }   1..$n_paragraphs;
}

method word () {
    return $self->process_random('word');
}

method words (INTEGER :$count = 5) {
    return join ' ', map {
        $self->process(random => 'word')
    }   1..$count;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Faker::Provider::Lorem - Faker Standard Lorem Provider

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Faker;
    use Faker::Provider::Lorem;

    my $faker = Faker->new;
    my $lorem = Faker::Provider::Lorem->new(factory => $faker);

    say $lorem->paragraph;

=head1 DESCRIPTION

Faker::Provider::Lorem is a L<Faker> provider which provides fake random text.
B<Note: This is an early release available for testing and feedback and as such
is subject to change.>

=head1 METHODS

=head2 paragraph

    $lorem->paragraph;

    # enim in sed nisi. optio itaque enim aut consequuntur nihil.
    # quisquam voluptatem velit eligendi et. accusantium sunt autem et.
    # aliquid autem sed. quia delectus maxime aut est quis. neque dolor.

The paragraph method generates a random ficticious paragraph.

=head2 paragraphs

    $lorem->paragraphs;

    # sed et consectetur possimus. in corporis id rerum. qui iste in rerum
    # praesentium voluptas accusamus quia.

    # nulla veniam praesentium tenetur deleniti impedit in quis maiores. neque
    # natus provident rerum natus perspiciatis in consequuntur molestiae.
    # reprehenderit maiores quibusdam voluptas sit.

    # unde in mollitia illum rerum. illum inventore quisquam provident
    # repudiandae cum ducimus aperiam quam. qui aperiam sequi impedit libero
    # adipisci inventore.

The paragraphs method generates a random ficticious paragraphs.

=head2 sentence

    $lorem->sentence;

    # quod at eos quaerat reiciendis.
    # ipsa non id qui aut.
    # et fugiat omnis sint aut.

The sentence method generates a random ficticious sentence.

=head2 sentences

    $lorem->sentences;

    # iure consequatur hic non quasi. voluptates et ut eligendi. quis ratione
    # numquam iure doloribus.

    # et iste commodi voluptatem repudiandae laudantium. dolorem laboriosam qui
    # sit aut et. expedita in eum natus.

    # blanditiis repudiandae et quas voluptate deleniti. autem sequi itaque
    # voluptate eveniet. praesentium fugiat sit in.

The sentences method generates a random ficticious sentences.

=head2 word

    $lorem->word;

    # quia
    # aliquam
    # eos

The word method generates a random ficticious word.

=head2 words

    $lorem->words;

    # amet qui quibusdam excepturi est
    # dolor qui nemo distinctio laborum
    # omnis non maxime numquam ea

The words method generates a random ficticious words.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
