package Log::ger::Screen::ColorScheme::Unlike;

our $DATE = '2017-08-03'; # DATE
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;
use Color::ANSI::Util qw(ansifg);
use Log::ger::Output::Screen ();

our %colors = (
    10 => "ED8C2B", # fatal
    20 => "CF4A30", # error
    30 => "911146", # warn
    40 => "35203B", # info
    50 => "",       # debug
    60 => "88A825", # trace
);

for (keys %colors) {
    $Log::ger::Output::Screen::colors{$_} =
        $colors{$_} ? ansifg($colors{$_}) : "";
}

1;
# ABSTRACT: Unlike color scheme

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Screen::ColorScheme::Unlike - Unlike color scheme

=head1 VERSION

version 0.003

=head1 SYNOPSIS

Via Perl code:

 use Log::ger::Output 'Screen';
 use Log::ger::Screen::ColorScheme::Unlike;
 use Log::ger;

 log_error("error");
 log_warn("warn");

Via command-line:

 % PERL5OPT=-MLog::ger::Screen::ColorScheme::Unlike yourscript.pl ...

Screenshot:

=for html <img src="https://st.aticpan.org/source/PERLANCAR/Log-ger-Screen-ColorSchemes-Kuler-0.003/share/images/unlike.png" />

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
