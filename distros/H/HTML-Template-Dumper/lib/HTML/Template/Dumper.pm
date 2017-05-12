
package HTML::Template::Dumper;
use strict;
use warnings;
use base 'HTML::Template';

our $VERSION = 0.1;

my ($format_obj, $output_filter);

BEGIN {
	use HTML::Template::Dumper::Data_Dumper;
	$format_obj = HTML::Template::Dumper::Data_Dumper->new();
}


sub set_output_format 
{
	my $self    = shift;
	my $format  = shift || die "Need an output format";
	my @rest    = @_;

	my $full_format = $format;  # Rule 1 (see POD doc)
	if($full_format !~ /::/) {  # Rule 2
		$full_format = "HTML::Template::Dumper::$format";
	}

	$format_obj = eval {
		eval "require $full_format"; 
		$@ and die $@;
		$full_format->new(@rest);
	};
	if($@) {
		# Rule 3
		$format_obj = eval {
			eval "require $format";
			$@ and die $@;
			$format->new(@rest);
		};
	}

	# Give up trying to load the module and just attempt 
	# to call it.  This would work if the module was in a 
	# package declaration placed inline with the calling 
	# file instead of a seperate file in @INC.
	# 
	$@ and ($format_obj = eval { $full_format ->new(@rest) });
	$@ and ($format_obj = eval { $format      ->new(@rest) });

	# If we still don't have it, give up (Rule 4)
	$@ and die "No such module -- $full_format";

	$format_obj->isa( 'HTML::Template::Dumper::Format' ) or die 
		ref $format_obj . 
		" is not a HTML::Template::Dumper::Format implementation";

	return 1;
}

sub get_output_format { ref $format_obj }

sub output 
{
	my $self = shift;
	my %in   = @_ ? @_ : ( );

	# Call HTML::Template->output(), since it could return 
	# errors if there was a problem with the input parameters 
	eval { $self->SUPER::output(@_) };
	$@ and die $@;

	my $ref = {
		map { $_ => $self->param($_) } $self->param(), 
	};

	my $output = $format_obj->dump($ref);
	$output_filter->(\$output) if $output_filter;

	if($in{print_to}) {
		print {$in{print_to}} ( $output );
		return undef; # As per HTML::Template docs
	}
	return $output;
}

sub set_output_filter 
{
	my $self = shift;
	my $filter = shift;
	die "set_output_filter() needs to be called with a code reference" 
		unless ref $filter eq 'CODE';
	
	$output_filter = $filter;
}

sub parse 
{
	my $self = shift;
	my $data = shift || return;

	if(! ref $self ) {
		# Called as a class method
		my $format = shift || 'Data_Dumper';
		my $dummy_tmpl = '<TMPL_VAR foo>';
		$self = $self->new( scalarref => \$dummy_tmpl );
		$self->set_output_format( $format );
	}

	return $format_obj->parse( $data );
}


1;
__END__


=head1 NAME 

  HTML::Template::Dumper - Output template data in a test-friendly format 

=head1 SYNOPSIS

  # Switch the module used to the regular HTML::Template when you're 
  # finished testing
  #
  #use HTML::Template;
  use HTML::Template::Dumper;
  
  my $tmpl = 
  	#HTML::Template
  	HTML::Template::Dumper
  	->new( . . . );
  $tmpl->set_output_format( 'YAML' ) if $tmpl->isa( 'HTML::Template::Dumper' );
  
  # Do processing for the template
  
  $tmpl->output();

=head1 DESCRIPTION 

This module helps you to test HTML::Template-based programs by printing only 
the information used to fill-in the template data.  This makes it much 
easier to automatically parse the output of your program.  Currently, data 
can be outputed by C<Data::Dumper> (default) or C<YAML>.

Note that the underlieing HTML::Template methods are still called, so 
options like C<strict> and C<die_on_bad_params> will still throw errors.

=head1 USAGE 

=head2 new 

Called just like the C<< HTML::Template->new() >> method.

=head2 set_output_format 

  $tmpl->set_output_format( 'YAML', @extra_params );

Set the output format.  Currently known formats are:

  Format Name         Module
  -------------       --------
  Data_Dumper         HTML::Template::Dumper::Data_Dumper
  YAML                HTML::Template::Dumper::YAML

The module is found by applying the following rules:

=over 4

=item 1. 

If the name has a C<::> anywhere, then it is taken as the full name 
of the module.

=item 2. 

Otherwise, the module is loaded from C<HTML::Template::Dumper::$NAME>, 
where C<$NAME> is what you passed to C<set_output_format>.

=item 3. 

If the name didn't have a C<::> in it, but it didn't pass rule #2, then 
take it as the full name of the module.

=item 4. 

If none of the above work, then call C<die>.

=back

In any of the cases, the module returned must inheirt from 
C<HTML::Template::Dumper::Format>.  Otherwise, C<die> is called.

Any parameters you pass after the format will be put directly into the 
formatter's C<new()> method.

=head2 output

Called just like the regular C<< HTML::Template->output() >>, but will 
return a simplified view of the template data instead of the full 
object.

The C<print_to> parameter is respected as specified in the 
C<HTML::Template> documentation.

=head2 set_output_filter 

Called with a reference to a subroutine. Before C<output> returns, this 
subroutine will be called with a scalar reference to the data that would 
otherwise have been directly returned by C<output>. Your filter subroutine 
can do any modification on the value it wants.  For instance, if you want 
the output to be (almost) valid HTML, you could write:

  $tmpl->set_output_filter( sub {
  	my $ref = shift;
	$$ref = q{
		<html>
		<head>
		<title>Debugging Output</title>
		</head>
		<body bgcolor="#FFFFFF">
		<pre>
	} . $$ref . q{
		</pre>
		</body>
		</html>
	}
  });

Note that the result may or may not work with C<parse>, depending on your 
filter and the format used by your dumper.

=head2 parse 

Called with the data that was returned by C<output()>.  Returns 
a hashref of all the parameters.

This can also be called as a class method, in which case it can take a 
second paramter containing the data format that the first paramter is 
in.  This second parameter has the same rules applied to it as 
C<set_output_format()>.

=head1 WRITING NEW FORMATTERS 

Formaters must inheirt from C<HTML::Template::Dumper::Format>.
There are two methods that need to be overridden. 

=head2 new 

Not called with anything.  Returns a blessed reference.  The default 
implementation blesses a scalar reference in order to save a little 
memory.  This should be sufficient for most formatters, but you can 
always override this method if you need it.

=head2 dump 

All formatters must override this method.

It is called with a single reference which is formatted and returned. 

=head2 parse 

All formaters must override this method.

It is called with a single scalar that holds the complete data returned 
by this formatter's C<dump> method.  It returns a hashref of all the 
parameters held in that dump.

=head1 BUGS 

Yes. 

=head1 AUTHOR 

  Timm Murray <tmurray@agronomy.org>
  http://www.agronomy.org
  CPAN ID: TMURRAY 

=head1 COPYRIGHT

Copyright 2003, American Society of Agronomy. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

a) the GNU General Public License as published by the Free Software 
Foundation; either version 2, or (at your option) any later version, or

b) the "Artistic License" which comes with Perl.


=head1 SEE ALSO 

perl(1). HTML::Template(3). Data::Dumper(3). YAML(3). 

=cut

