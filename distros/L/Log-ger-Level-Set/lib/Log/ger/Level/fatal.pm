package Log::ger::Level::fatal;

our $DATE = '2018-03-12'; # DATE
our $VERSION = '0.001'; # VERSION

use Log::ger ();
$Log::ger::Current_Level = $Log::ger::Levels{fatal};

1;
# ABSTRACT: Set log level to fatal

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Level::fatal - Set log level to fatal

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Log::ger::Level::fatal;

is a shortcut for something:

 use Log::ger ();
 $Log::ger::Current_Level = $Log::ger::Levels{fatal};

On the command-line, this:

 % LOG_LEVEL=fatal perl -MLog::ger::Level::FromEnv ...

can be shortened somewhat to:

 % perl -MLog::ger::Level::fatal ...

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
