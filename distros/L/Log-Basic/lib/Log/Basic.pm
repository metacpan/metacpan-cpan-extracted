package Log::Basic;

use 5.020002;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	debug info warning error msg sep fatal
);

our $VERSION = '1.1';

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
our $DEFAULT_VERBOSITY = 4;
our $VERBOSITY = $DEFAULT_VERBOSITY;

# ------------------------------------------------------------------------------
# Internal functions
# ------------------------------------------------------------------------------
sub now {
	my ($S,$M,$H,$d,$m,$y) = localtime(time);
	return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $y+1900, $m+1 ,$d,$H,$M,$S);
}

# ------------------------------------------------------------------------------
# File handle
# ------------------------------------------------------------------------------
my $n=now(); $n=~s/[- :]//g;
my $outfile = "$n-$$.log";

open(OUT, ">>", "./log/$outfile")
  or open(OUT, ">>", "$outfile")
  or die("Could not open '$outfile': $!");

# ------------------------------------------------------------------------------
# Exported functions
# ------------------------------------------------------------------------------
sub debug {
	print "[debug] [proc:$$] [".now()."] @_\n" if $VERBOSITY > 4;
	print OUT "[debug] [proc:$$] [".now()."] @_\n" if(fileno(OUT));
}

sub info {
	print "[info]  [proc:$$] [".now()."] @_\n" if $VERBOSITY > 3;
	print OUT "[info]  [proc:$$] [".now()."] @_\n" if(fileno(OUT));
}

sub warning {
	print "[warn]  [proc:$$] [".now()."] @_\n" if $VERBOSITY > 2;
	print OUT "[warn]  [proc:$$] [".now()."] @_\n" if(fileno(OUT));
}

sub error {
	print "[error] [proc:$$] [".now()."] @_\n" if $VERBOSITY > 1;
	print OUT "[error] [proc:$$] [".now()."] @_\n" if(fileno(OUT));
}

sub msg {
	print "[msg]   [proc:$$] [".now()."] @_\n" if $VERBOSITY > 0;
	print OUT "[msg]   [proc:$$] [".now()."] @_\n" if(fileno(OUT));
}

sub fatal {
	print OUT "[fatal] [proc:$$] [".now()."] @_\n" if(fileno(OUT));
	die "[fatal] [proc:$$] [".now()."] @_\n";
}

sub sep {
	my $str = join(' ', "[proc:$$]", @_);
	print '---', $str, '-' x (80 - (3 + length $str)), "\n";
	print OUT '---', $str, '-' x (80 - (3 + length $str)), "\n";
}

END {
	close OUT if(fileno(OUT));
}
1;
__END__

=head1 NAME

Log::Basic - Perl extension for simple logging.

=head1 SYNOPSIS

  perl -MLog::Basic -e 'info "hey"'
  
  use Log::Basic;
  $Log::Basic::VERBOSITY=3;
  debug "stuff"; # won't be printed
  info "here is the info message"; # won't be printed
  warning "wow! beware!";
  error "something terrible happend !";
  msg "this message will be displayed whatever the verbosity level";
  sep "a separator";
  fatal "fatal error: $!";

=head1 DESCRIPTION

Log::Basic displays formatted messages according to the defined verbosity level (default:4).

=head2 Format

Log messages are formatted as: `[<level>] <date> - <message>`.
Dates are formatted as: `YYYY-MM-DD hh:mm:ss`.
Your message could be whatever you what.

=head2 Levels

Verbosity and associated levels are:

=over

=item - level 1, `msg`

=item - level 2, `error`

=item - level 3, `warn`

=item - level 4, `info`

=item - level 5, `debug`

=item - no level, `fatal`

=back

Setting verbosity to 3 will print `warn`, `info`, and `msg` only.

=head2 Special cases

`fatal` is a special level, corresponding to perl's `die()`.

Separator is a special functions which display a line of 80 dashes, with your message eventually.

=head2 Saving to file

All messages will also be appended to a file. If a `./log/` folder exists, a `$$.$0.log` file is created within this folder, otherwise the `$$.$0.log` file is created in the current directory.

=head1 EXPORT

debug info warning error msg sep fatal

=head1 AUTHOR

Kevin Gravouil, E<lt>k.gravouil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Kevin Gravouil

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

