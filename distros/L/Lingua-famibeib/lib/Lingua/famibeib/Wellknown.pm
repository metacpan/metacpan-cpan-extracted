# Copyright (c) 2025-2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: database of famibeib words


package Lingua::famibeib::Wellknown;

use v5.16;
use strict;
use warnings;

use Carp;
use Lingua::famibeib::Word;
use Lingua::famibeib::Modifier;
use Lingua::famibeib::Prefix; # This will also load some prefixes
use Data::Identifier::Util;
use Data::Displaycolour v0.07;
use Data::IconText v0.06;

our $VERSION = v0.07;

use parent qw(Data::Identifier::Interface::Known);

my @_wellknown_words = map {Lingua::famibeib::Word->new(from => $_)->register} (
    (map {$_, $_.'ab'} qw(baba babe babi  bafa bafe bafi bafo  baka bake baki bako baku)), # Pronouns
    (map {Lingua::famibeib::Word->new(number => $_)} -1 .. 32), # Numbers
    (qw(fokiba fokibe fokibi  fokifa fokife fokifi  fokika fokike fokiki fokiko  fokila)), # Colours
    (qw(febaba febabo  febasu febebe  febeba febe  febeto)), # Animals
    (map {'tu'.$_, 'tu'.$_.'al'} qw(ba be bi bo  ma me mi  sa se si so su  ta te ti to tu)), # Structure I
    (map {     $_,      $_.'al'} qw(tusifa tusife tusifi tusifo)), # Structure II
    (map {     $_,      $_.'ol'} qw(faba fabe fabi fabo fabu  fafa fafe fafi fafo fafu  faka fake faki fako faku  fala fale fali falo falu
                                    fama fame fami famo famu  fasa fase fasi faso fasu  fata fate fati fato fatu)), # Common Verbs
    (map {     $_,      $_.'am'} qw(fababa fababe fababi fababo fababu  fabafa fabafe fabafi  fabaka fabake)), # Relatives
    (map {     $_,      $_.'am'} qw(fabala fabale fabali fabalu  fabama fabame  fabasa fabase fabasi fabaso fabasu)), # Other Persons
);

my @_wellknown_modifiers = map {Lingua::famibeib::Modifier->new(from => $_)->register} (
    qw(ab eb ib ub  af ef  ak ek ok uk  al il ol  am em im),
);

my @_wellknown_prefixs = map {Lingua::famibeib::Prefix->new(string => $_)->register} (
    qw(ba be  fa fe fi fo fu  ta to tu),
);

my %_concept = (
    # Colours:
    fokiba      => 'c9ec3bea-558e-4992-9b76-91f128b6cf29',
    fokibe      => '5c41829f-5062-4868-9c31-2ec98414c53d',
    fokibi      => '2892c143-2ae7-48f1-95f4-279e059e7fc3',

    fokifa      => 'c0e957d0-b5cf-4e53-8e8a-ff0f5f2f3f03',
    # fokife
    fokifi      => 'abcbf48d-c302-4be1-8c5c-a8de4471bcbb',

    fokika      => '3dcef9a3-2ecc-482d-a98b-afffbc2f64b9',
    # fokike
    # fokiki
    fokiko      => 'a30d070d-9909-40d4-a33a-474c89e5cd45',

    fokila      => 'f2e45f11-b1a8-421f-9c03-61a30bd23e78',

    # Animals:
    febaba      => '571fe2aa-95f6-4b16-a8d2-1ff4f78bdad1',
    febabo      => '36297a27-0673-44ad-b2d8-0e4e97a9022d',
    febasu      => '838eede5-3f93-46a9-8e10-75165d10caa1',
    febebe      => '252314f9-1467-48bf-80fd-f8b74036189f',
    febeba      => '5d006ca0-c27b-4529-b051-ac39c784d5ee',
    febe        => '95f1b56e-c576-4f32-ac9b-bfdd397c36a6',
    febeto      => 'dcf8f4f0-c15e-44bd-ad76-0d483079db16',

    # Relatives:
    fababaam    => '3efce853-eae9-4429-9d5d-c4420f846005',
    fababeam    => 'a3e1528a-5258-420d-92aa-401d973c43a8',
    fababiam    => '2ef71908-a411-464d-9de2-53da0b3505ba',
    fababoam    => '30cc2c34-4296-4f9a-8ca6-dd139247dd3c',
    fababuam    => 'f4423fe9-b535-4f3b-8d7f-b0c863f6b525',

    fabafaam    => 'e7c73208-81ea-4ac7-b937-87070bbb9126',
    fabafeam    => 'cf65827f-bc2b-49fa-a270-16fee39993a1',
    fabafiam    => 'b148ee3a-2547-4b0a-a7e2-a160024c4053',

    #fabakaam    => '',
    #fabakeam    => '',
);

my @_wellknown_extra = (
    Lingua::famibeib::Word->natural_language, # force load
    Data::Identifier::Util->register_generator(
        'e2afa39e-fd57-45f8-89fd-8662b275cc68',
        namespace   => '10ce38bf-6238-4ed7-96ef-98ea9642a4c6',
        style       => 'id-based',
    ),
    Data::Identifier::Util->register_generator(
        '306baa6e-e672-4327-a6b4-ba1d3de89a1e',
        namespace   => '5c2b24f0-e0d9-4746-bd72-0d07061d0dd7',
        style       => 'id-based',
    ),
);

foreach my Lingua::famibeib::Word $word (@_wellknown_words) {
    my $id = $word->as('Data::Identifier')->register;
    my $str = $word->as_string;
    my $concept;

    $concept //= Data::Identifier->new(from => $_concept{$str}) if defined $_concept{$str};
    $concept //= eval {$word->as_number('Data::Identifier')};

    next unless defined $concept;

    $concept->register;

    push(@_wellknown_extra, $concept);

    foreach my $obj ($word, $id) {
        $obj->Data::Displaycolour::mark(for => $concept);
        $obj->Data::IconText::mark(for => $concept);
    }
}

# ---- Private helpers ----

sub _known_provider {
    my ($pkg, $class, %opts) = @_;
    croak 'Unsupported options passed' if scalar(keys %opts);
    if ($class eq 'word') {
        return (\@_wellknown_words, rawtype => 'Lingua::famibeib::Word');
    } elsif ($class eq 'modifier') {
        return (\@_wellknown_modifiers, rawtype => 'Lingua::famibeib::Modifier');
    } elsif ($class eq 'prefix') {
        return (\@_wellknown_prefixs, rawtype => 'Lingua::famibeib::Prefix');
    } elsif ($class eq ':all') {
        return ([@_wellknown_words, @_wellknown_modifiers, @_wellknown_prefixs, @_wellknown_extra], rawtype => 'Data::Identifier::Interface::Simple');
    }
    croak 'Unsupported class';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::famibeib::Wellknown - database of famibeib words

=head1 VERSION

version v0.07

=head1 SYNOPSIS

    use Lingua::famibeib::Wellknown;

This package holds a number of well known famibeib words.
Those words will be automatically registered using L<Lingua::famibeib::Word/register>.
This is useful when working with long texts.
Also additional information may be provided by this package for individual words.

This module inherits from L<Data::Identifier::Interface::Known>.

B<Note:>
This package might also register L<Data::Identifier> objects related to the words.
Depending on the usecase results might improve if L<Data::Identifier::Wellknown> is also loaded.

=head1 CLASSES

The following classes are supported:

=head2 :all

All objects known by this module.
This includes all from the other classes.
It may also contain additional entries.

=head2 word

All words known to this module.

=head2 modifier

All modifiers known to this module.

=head2 prefix

All prefixes known to this module.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
