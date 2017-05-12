package IO::Simple;

use 5.006;
use strict;
use warnings;

require Exporter;
require IO::File;

our @ISA = qw(Exporter IO::File);

use Data::Dumper;
our %EXPORT_TAGS = ( 'all' => [ qw(
   file	slurp
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.04';

use Carp;

=head1 NAME

IO::Simple - Adds error checking to file handles and provides per file handle options.

=head1 SYNOPSIS

You can export the C<file> method as below

  use IO::Simple ':all';
  
  my $fh = file('test.txt', 'w');          #dies if file can't be opened
  $fh->say("This is a line");             #say appends new line
  $fh->print("This has no new line!!!");  #regular print behavior
  $fh->close();                           #dies on failure

  my $contents = file('test.txt')->slurp();

Or you can use the C<new> class method

  use IO::Simple;
  my $fh = new IO::Simple('test.txt');

=head1 DESCRIPTION

IO::Simple provides a thin layer over IO::File.  This layer causes files to
default to opening in read mode and to croaking on failure opening, closeing
or printing to files. It provides methods to set $\, $/, $:, $^L and $, on a 
per handle basis and a slurp function.

=head1 REASONING

You can get similar results using a combination of IO::All, Fatal and 
File::Slurp.  I found that fatal didn't provide as descriptive as errors as I
wanted, and IO::All was overly bloated so this module was born to fill in 
those gaps.

=head1 METHODS

=over 4

=cut

my $data = {};
sub data { $data };

# internal method for inside out object operation
sub id {
    my $self = shift;
	return 0+$self;
}

=item new IO::Simple ( [FILENAME [,MODE, [OPTIONS]]])

Passes any arguments to C<< $self->open >> for processing, otherwise simply 
returns a new object.

=cut

sub new {
    my $type  = shift;
	my $class = ref($type) || $type || "IO::Simple";
	my $self  = $class->SUPER::new();
	
	$data->{id($self)} = {
			file_name => '',
			mode      => '',
            autochomp => 1
	};
	
	$self->open(@_) if (@_);
	return $self;
}

=item $fh->open ( FILENAME [,MODE, [OPTIONS]])

C<file> accepts up to three parameters. If only FILENAME is supplied then
the default mode is 'read' The mode can be one of 'r',' 'read', 'w', 'write',
'a', 'append' which translate to '<', '>', and '>>'.  The third parameter is
a hash of options. It also adds some magic so that the '-' file name will 
cause STDIN or STDOUT to be opened depending on the mode.

    Option                       Sets
	line_break_characters        $:
    format_formfeed              $^L
    output_field_separator       $,
    output_record_separator      $\
    input_record_separator       $/
	autochomp                    auto chomp on readline or slurp

=cut

sub open {
	my $self      = shift;
	my $file_name = shift;
	my $mode      = shift || 'r';
	if ($file_name eq '-') {
		if ($mode =~ /r|</) {
			$self->fdopen('STDIN', $mode) or croak "Opening '$file_name' for '$mode' failed: $!";
		} else {
		    $self->fdopen('STDOUT', $mode) or croak "Opening '$file_name' for '$mode' failed: $!";
		}
	} else {
		$self->SUPER::open($file_name, $mode) or croak "Opening '$file_name' for '$mode' failed: $!";
	}
	$data->{id($self)} = {
			%{$data->{id($self)}},
			@_
	};
	return $self;
};

=item C<reopen> ( [MODE] )

Reopen a previously opened file with the same mode or a new mode.

	my $fh = file('test');  #open it for reading;
	$fh->close;
	$fh->reopen('a');  #reopen the file for writing.

=cut
	
sub reopen {
	my $self = shift;
	my $data = $data->{id($self)};
	my $mode = shift || $data->{mode};
	croak "No file has been opened to be reopened." unless defined $data;
	$self->open($data->{file_name}, $mode);
}

=item C<file> ( FILENAME [,MODE, [OPTIONS]])

C<file> accepts up to three parameters. If only one is supplied then the
default mode is 'read' The mode can be one of 'r',' 'read', 'w', 'write',
'a', 'append' which translate to '<', '>', and '>>'.  The third parameter
is a hash of options. By default C<autochomp> is on, but you can use this
to disable it if you prefer. which would cause the slurp method to chomp 
each line in array context.  C<irs> shoft for "Input Record Seperator" lets
you set a default value for C<$\> that will be used for C<readline> and 
C<slurp> operations.

   my $read  = file('test');
   my $write = file('test', 'w');

   my $not_chomped = file('test', 'r', autochomp => 0)
   my @lines       = $not_chomped->slurp();
   
   my $pipedel = file('test', 'r', irs => '|')
   my @fields  = $pipedel->slurp();

=cut

sub file {
	my $self = new IO::Simple;
	$self->open(@_) if @_;
	return $self;
}

=item $fh->close

Wrapper for IO::Handle close with added error handling.

=cut

sub close {
	my $self = shift;
	my $data = $data->{id($self)};
	croak "File '$data->{file_name}' is not open."  unless $self->opened;
	$self->SUPER::close() or croak "Failed to close '$data->{file_name}' : $!";
}

#internal function to wrap functions in error catching
sub _protect {
    my $function  = shift;
	my $self      = shift;
	my $data = $data->{id($self)};
	
	croak "File '$data->{file_name}' is not opened."  unless $self->opened;
	$" = ',';
	$self->can("SUPER::$function")->($self,@_) or croak "Failed to $function(@_): $!";
}

# Protect functions from IO::Seekable
sub seek     { _protect('seek', @_) }
sub tell     { _protect('tell', @_) }
sub truncate { _protect('truncate', @_) }
sub sysseek  { _protect('sysseek', @_) }
sub setpos   { _protect('setpos', @_) }
sub getpos   { _protect('getpos', @_) }


=item PerlVar per Handle Methods

Stores your choice and later localizes the perlvar and sets it appropriately 
during output operations. Returns current value if no STR is provided.

	$fh->format_line_break_characters( [STR] ) $:
	$fh->format_formfeed( [STR])               $^L
	$fh->output_field_separator( [STR] )       $,
	$fh->output_record_separator( [STR] )      $\

Stores your choice and later localizes the perlvar and sets it appropriately
during input operations. Returns current value if no STR is provided.

	$fh->input_record_separator( [STR] )       $/


=cut
sub set_option {
	my $self  = shift;
	@_ == 1 || @_ == 2 or croak "usage: \$fh->set_option('option'[ ,value]);";
	my $option = shift;
	return $self->can("SUPER::$option")->(@_) unless ref($self);

	my $data = $data->{id($self)};
	return $data->{$option} unless @_ == 1;
	$data->{$option} = shift;
}	

sub format_line_break_characters { 	shift->set_option('format_line_break_characters', @_); }
sub format_formfeed              {	shift->set_option('format_formfeed'             , @_); }
sub output_field_separator       {	shift->set_option('output_field_separator'      , @_); }
sub output_record_separator      {	shift->set_option('output_record_separator'     , @_); }
sub input_record_separator       {  shift->set_option('input_record_separator'      , @_); }


=item $fh->print

Wrapper for IO::Handle C<print> with added error handling and localizes
C<$:>, C<$^L>, C<$,>, C<$\> and sets them properly for each file handle.

=cut

sub say   { shift->print(@_,"\n"); }
sub print {
	my $self = shift;
	croak "File '$data->{file_name}' is not opened."  unless $self->opened;		
	my $data = $data->{id($self)};

    local $:  = exists $data->{format_line_break_characters} ?  $data->{format_line_break_characters} : $:;
    local $^L = exists $data->{format_formfeed}              ?  $data->{format_formfeed}              : $^L;	
	local $,  = exists $data->{output_field_separator}       ?  $data->{output_field_separator}       : $,;	
	local $\  = exists $data->{output_record_separator}      ?  $data->{output_record_separator}      : $\;	
	
	print $self @_ or croak "Failed to print to '$data->{file_name}': $!";
	return $self;
}

=item IO::Simple::slurp(FILE [,SEP])

Takes a file name an slurps up the file.  In list context it uses the SEP 
and outputs an array of lines in scalar context it ignores the SEP and 
returns the entire file in a scalar.

   use IO::Simple qw/slurp/;
   my $content = slurp('test');

=item $fh->slurp([SEP])

C<slurp> returns the remaining contents of the file handle.  If used in list
context it returns the lines of the file in an array (setting $/ = SEP),
otherwise it returns the entire file slurped into a scalar.  Unless disablled
with autochomp, lines returned in list context will be chomped.

   my $content = file('test')->slurp();

=cut

sub slurp { 
	my $self = shift;
	unless ($self->isa('IO::Simple')) {
		$self = file($self);
	}
	croak "File '$data->{file_name}' is not opened."  unless $self->opened;	
	if (wantarray) {
		return $self->readline(@_);
	} else {
		return $self->readline(undef);
	}
}

sub readline {
	my $self = shift;

	my $data = $data->{id($self)};
	croak "File '$data->{file_name}' is not opened."  unless $self->opened;
	local $/ = $/;
	if (@_) {
	    $/ = shift;		
	} elsif (exists $data->{input_record_separator}) {
		$/ = $data->{input_record_separator};
    }
	
	if (wantarray) {
	    my @lines = <$self>;
	    chomp(@lines) if $data->{autochomp};
	    return @lines;
	} else {
		my $line = <$self>;
		chomp($line)  if $data->{autochomp};;
		return $line;
	}
}

sub DESTROY {
   my $self = shift;
   delete $data->{id($self)};   
}

1;

=back

=head1 EXPORT

Optionaly exports two functions C<file> and C<slurp> or use C<:all> to 
import both. No methods are exported by default.

=head1 CAVEAT

The error checking only works when you use the object methods.  This 
allows you to use the builtins when wish to handle your own error checking.

   my $fh = file('test.txt');
   $fh->print("Hello Wolrd");    #results in error
   print $fh "Hello World";      #doesn't through error.
   
   my $fh = new IO::Simple;
   $fh->open('test');            #throws error if test doesn't exist
   open($fh, '<', 'test');       #allows you to handle errors on your own.

If you don't use the open method the errors will not know which file you
opened or what mode you opened it in.

=head1 SEE ALSO

L<IO::All>,
L<IO::File>,
L<Perl6::Slurp>,
L<File::Slurp>,
L<Fatal>

=head1 AUTHOR

Eric Hodges <eric256@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Eric Hodges

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
