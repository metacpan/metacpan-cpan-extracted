package Grizzly::Command::news;

# ABSTRACT: Gets the stock news for the given symbol

use Grizzly -command;
use v5.36;

use Grizzly::Data::Article qw(news_info);

sub command_names { qw(news --news -n) }

sub abstract { "display stock news" }

sub description { "Display the any news on the stock." }

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error("Need a symbol args") unless @$args;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    news_info(@$args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Grizzly::Command::news - Gets the stock news for the given symbol

=head1 VERSION

version 0.111

=head1 SYNOPSIS

    grizzly news [stock symbol]

=head1 DESCRIPTION

The news feture will output stock in formation on the inputted ticker symbol.

=head1 NAME

Grizzly::Command::news

=head1 API Key

You will need to get a free API key from L<NewsAPI|https://newsapi.org/>. Afterwards you will need to set the NEWS_API_KEY environment variable to the API key.

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Nobunaga.

MIT License

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Nobunaga.

This is free software, licensed under:

  The MIT (X11) License

=cut
