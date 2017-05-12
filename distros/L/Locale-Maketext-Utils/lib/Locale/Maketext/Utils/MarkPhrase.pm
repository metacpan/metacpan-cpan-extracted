package Locale::Maketext::Utils::MarkPhrase;

sub import {
    no strict 'refs';
    *{ caller() . '::translatable' } = \&translatable;
}

sub translatable {
    return $_[0];
}

1;
