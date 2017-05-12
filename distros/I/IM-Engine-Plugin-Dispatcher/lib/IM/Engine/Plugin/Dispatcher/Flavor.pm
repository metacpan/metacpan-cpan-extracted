package IM::Engine::Plugin::Dispatcher::Flavor;
use Moose;
extends 'IM::Engine::Plugin';
with 'IM::Engine::Plugin::Dispatcher::AugmentsDispatcher';

my @greetings = (
    sub { "Hi " . shift->sender->name . "!" },
    sub { "Hello, how may I serve you?" },
    sub { "Hello, this is an operator. Let's have a normal, human interaction." },
);

my @goodbyes = (
    sub { "See ya " . shift->sender->name . "!" },
    sub { "Bye for now." },
);

my @welcomes = (
    sub { "You're welcome!" },
    sub { "No problemo." },
    sub { "Don't mention it." },
    sub { "Just doing my job, " . shift->sender->name . "!" },
);

sub new_rules {
    return (
        Path::Dispatcher::Rule::Regex->new(
            regex => qr/^(hi|hello|hey|howdy)\b/i,
            block => sub { $greetings[rand @greetings]->(@_) },
        ),
        Path::Dispatcher::Rule::Regex->new(
            regex => qr/^((good[- ]?)?bye|(c|see )ya|so long)\b/i,
            block => sub { $goodbyes[rand @goodbyes]->(@_) },
        ),
        Path::Dispatcher::Rule::Regex->new(
            regex => qr/^(thanks?)\b/i,
            block => sub { $welcomes[rand @welcomes]->(@_) },
        ),
    );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 NAME

IM::Engine::Plugin::Dispatcher::Flavor

=head1 DESCRIPTION

This plugin extends your dispatcher with silly flavor messages. This plugin
responds to messages like "hello", "hi", "bye", "thanks", etc. with similar
sentiments.

=cut

