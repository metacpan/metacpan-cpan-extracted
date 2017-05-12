
#=======================================================================
#
#   Copyright (c) 2002-2003 Kasper Dziurdz. All rights reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   Artistic License for more details.
#
#   Please email me any comments, questions, suggestions or bug 
#   reports to: <kasper@repsak.de>
#
#=======================================================================

package HTML::KTemplate;
use strict;
use Carp;
use File::Spec;

use vars qw(
	$VAR_START_TAG $VAR_END_TAG 
	$BLOCK_START_TAG $BLOCK_END_TAG
	$INCLUDE_START_TAG $INCLUDE_END_TAG
	$ROOT $CHOMP $VERSION $CACHE
	$FIRST $INNER $LAST
);

$VERSION = '1.33';

$VAR_START_TAG = '[%';
$VAR_END_TAG   = '%]';

$BLOCK_START_TAG = '<!--';
$BLOCK_END_TAG   = '-->';

$INCLUDE_START_TAG = '<!--';
$INCLUDE_END_TAG   = '-->';

$ROOT  = undef;
$CHOMP = 1;
$CACHE = {};

$FIRST = { 'FIRST' => 1, 'first' => 1 };
$INNER = { 'INNER' => 1, 'inner' => 1 };
$LAST  = { 'LAST'  => 1, 'last'  => 1 };


sub TEXT   () { 0 }
sub VAR    () { 1 }
sub BLOCK  () { 2 }
sub FILE   () { 3 }
sub IF     () { 4 }
sub ELSE   () { 5 }
sub UNLESS () { 6 }
sub LOOP   () { 7 }

sub TYPE   () { 0 }
sub IDENT  () { 1 }
sub STACK  () { 2 }

sub NAME   () { 0 }
sub PATH   () { 1 }


sub new {

	my $class = shift;
	my $self = {
		'vars'   => [{}],  # values for template vars
		'loop'   => [],    # loop context variables
		'block'  => undef, # current block reference
		'files'  => [],    # file paths for include
		'output' => '',    # template output
		'config' => {      # configuration
			'cache'        => 0,
			'strict'       => 0,
			'no_includes'  => 0,
			'max_includes' => 15,
			'loop_vars'    => 0,
			'blind_cache'  => 0,
			'include_vars' => 0,
			'parse_vars'   => 0,
		},
	};

	$self->{'config'}->{'root'} = shift if @_ == 1;
	croak('Odd number of option parameters') if @_ % 2 != 0;

	# load in all option parameters
	$self->{'config'}->{$_} = shift while $_ = lc shift;

	$self->{'config'}->{'root'} = $ROOT
		unless exists $self->{'config'}->{'root'};

	$self->{'config'}->{'cache'} = 1
		if $self->{'config'}->{'blind_cache'};

	bless ($self, $class);
	return $self;

}


sub assign {

	my $self = shift;
	my ($target, $block);

	# odd number of arguments: block
	if (@_ % 2 != 0 && @_ >= 3) {
		$self->block(shift);
		++$block; 
	}
	
	# if a block reference is defined,
	# assign the variables to the block
	$target = defined $self->{'block'}
		? $self->{'block'}->[ $#{ $self->{'block'} } ]
		: $self->{'vars'}->[0];

	if (ref $_[0] eq 'HASH') {
		# copy data for faster variable lookup
		@{ $target }{ keys %{$_[0]} } = values %{$_[0]};
	} else {
		my %assign = @_;
		@{ $target }{ keys %assign } = values %assign;
	}
	
	# remove block reference
	$self->block() if $block;

	return 1;

} 


sub block {
# - creates a new loop in the defined block
# - sets a reference so all future variable values will
#   be assigned there (until this method is called again)

	my $self = shift;
	my (@ident, $root, $key, $last_key);
	
	# no argument: undefine block reference 
	if (!defined $_[0] || !length $_[0]) {
		$self->{'block'} = undef; 
		return 1;
	}
	
	push @ident, split /\./, shift while @_;
	$last_key = pop @ident;
	
	$root = $self->{'vars'}->[0];
	
	foreach $key (@ident) {
	
		# hash reference: perfect!
		if (ref $root->{$key} eq 'HASH') {
		$root = $root->{$key};
		}
	
		# array reference: block continues in hash 
		# reference at the end of the array
		elsif (ref $root->{$key} eq 'ARRAY' 
		  && ref $root->{$key}->[ $#{ $root->{$key} } ] eq 'HASH' ) {
		$root =  $root->{$key}->[ $#{ $root->{$key} } ];
		}
		
		else { # create new hash reference
		$root = $root->{$key} = {};
		}
		
	}
	
	if (ref $root->{$last_key} eq 'ARRAY') {
		# block exists: add new loop
		push @{ $root->{$last_key} }, {};
	} else {
		# create new block
		$root->{$last_key} = [{}];
	}
	
	$self->{'block'} = $root->{$last_key};
	
	return 1;
	
}


sub process {

	my $self = shift;

	foreach (@_) {
		next unless defined;
		$self->_include($_);
	}

	return 1;
	
}


sub _include {

	my $self = shift;
	my $filename = shift;
	my ($stack, $filepath);
	
	# check whether includes are disabled
	if ($self->{'config'}->{'no_includes'} && scalar @{ $self->{'files'} } != 0) {
		croak('Include blocks are disabled at ' . $self->{'files'}->[0]->[NAME])
			if $self->{'config'}->{'strict'};
		return; # no strict
	}
	
	# check for recursive includes
	croak('Recursive includes: maximum recursion depth of ' . $self->{'config'}->{'max_includes'} . ' files exceeded')
		if scalar @{ $self->{'files'} } > $self->{'config'}->{'max_includes'}; 

	($stack, $filepath) = $self->_load($filename);
	
	# add file path to use as include path
	unshift @{ $self->{'files'} }, [ $filename, $filepath ]
		if defined $filepath;
	
	# create output
	$self->_output($stack);
	
	# delete file info if it was added
	shift @{ $self->{'files'} }	if defined $filepath;

}


sub _load {
# - loads the template file from cache or hard drive
# - returns the parsed stack and the full template path

	my $self = shift;
	my $filename = shift;
	my ($filepath, $mtime, $filedata);
	
	# slurp the file
	local $/ = undef;
	
	# when the passed argument is a reference to a scalar,
	# array or file handle, load and use it as template

	if (ref $filename eq 'SCALAR') {
		# skip undef and do not change passed scalar
		$filedata = defined $$filename ? $$filename : '';
		return $self->_parse(\$filedata, '[scalar_ref]');
	}

	if (ref $filename eq 'ARRAY') {
		$filedata = join("", @$filename);
		return $self->_parse(\$filedata, '[array_ref]');
	}

	if (ref $filename eq 'GLOB') {
		$filedata = readline($$filename);
		$filedata = '' unless defined $filedata; # skip undef
		return $self->_parse(\$filedata, '[file_handle]');
	}

	# file handle (no reference)
	if (ref \$filename eq 'GLOB') {
		$filedata = readline($filename);
		$filedata = '' unless defined $filedata; # skip undef
		return $self->_parse(\$filedata, '[file_handle]');
	}

	($filepath, $mtime) = $self->_find($filename);
	
	croak("Can't open file $filename: file not found") 
		unless defined $filepath;
	
	if ($self->{'config'}->{'cache'}) {
		# load parsed template from cache
		$filedata = $CACHE->{$filepath};
		
		return ($filedata->[0], $filepath)
			if $self->{'config'}->{'blind_cache'} && defined $filedata;
		return ($filedata->[0], $filepath) 
			if defined $filedata && $filedata->[1] == $mtime;
	}
	
	open (TEMPLATE, '<' . $filepath) ||
		croak("Can't open file $filename: $!");
	$filedata = <TEMPLATE>;
	close TEMPLATE;
	
	$filedata = $self->_parse(\$filedata, $filename);
	
	# commit to cache
	$CACHE->{$filepath} = [ $filedata, $mtime ]
		if $self->{'config'}->{'cache'};

	return ($filedata, $filepath);

}


sub _find {
# - searches for the template file in the 
#   root path or from where it was included
# - returns a full path and the mtime or 
#   undef if the file cannot be found

    my $self = shift;
    my $filename = shift;
    my ($inclpath, $filepath);

    $filepath = defined $self->{'config'}->{'root'}
        ? File::Spec->catfile($self->{'config'}->{'root'}, $filename)
        : File::Spec->canonpath($filename);

	return $filepath if $self->{'config'}->{'blind_cache'}
		&& defined $CACHE->{$filepath};
	return ($filepath, (stat(_))[9]) if -e $filepath;

	# check path from where the file was included
    if (defined $self->{'files'}->[0]->[PATH]) {
		$inclpath = $self->{'files'}->[0]->[PATH];
        $inclpath = [ File::Spec->splitdir($inclpath) ];
        $inclpath->[$#$inclpath] = $filename;
        $filepath = File::Spec->catfile(@$inclpath);
		$filepath = File::Spec->canonpath($filepath);
		
		return $filepath if $self->{'config'}->{'blind_cache'}
			&& defined $CACHE->{$filepath};
		return ($filepath, (stat(_))[9]) if -e $filepath;
		
		# check path from variable
		if ($self->{'config'}->{'include_vars'}) {
			$filepath = File::Spec->canonpath( $self->_get($filename) );
			return $filepath if $self->{'config'}->{'blind_cache'}
				&& defined $CACHE->{$filepath};
			return ($filepath, (stat(_))[9]) if -e $filepath;
		}
		
    }
	
    return undef;
	
}


sub _parse {
# - parses the template data passed as a reference 
# - returns the finished stack

	my $self = shift;
	my $filedata = shift;
	my $filename = shift;
	my ($text, $tag, $type, $ident);
	my ($regexp, $line, $block, $space);
	my (@idents, @pstacks);

	$line = 1; # current line
	@pstacks = ([]);
	
	# block and include tags are the same by default.
	# if that wasn't changed, use a faster regexp.
	
	$regexp = $BLOCK_START_TAG eq $INCLUDE_START_TAG 
		&& $BLOCK_END_TAG eq $INCLUDE_END_TAG
		
		? qr/^
			(.*?)
			(
				\Q$VAR_START_TAG\E		
				\s*
				([\w.-]+)
				\s*			
				\Q$VAR_END_TAG\E
			|
				\Q$BLOCK_START_TAG\E		
				\s*
				(?:
					(
						[Bb][Ee][Gg][Ii][Nn]
						|
						[Ee][Nn][Dd]
						|
						[Ii][Ff]
						|
						[Ll][Oo][Oo][Pp]
						|
						[Ee][Ll][Ss][Ee]
						|
						[Uu][Nn][Ll][Ee][Ss][Ss]
					) 
					(?: \s+ ([\w.-]+) )?
				|
					([Ii][Nn][Cc][Ll][Uu][Dd][Ee])\s+
					(?: "([^"]*?)" | '([^']*?)' | (\S*?) )
				)
				\s*
				\Q$BLOCK_END_TAG\E
			)
			/sx
			
		: qr/^
			(.*?)
			(
				\Q$VAR_START_TAG\E		
				\s*
				([\w.-]+)
				\s*			
				\Q$VAR_END_TAG\E
			|
				\Q$BLOCK_START_TAG\E		
				\s*
				(
					[Bb][Ee][Gg][Ii][Nn]
					|
					[Ee][Nn][Dd]
					|
					[Ii][Ff]
					|
					[Ll][Oo][Oo][Pp]
					|
					[Ee][Ll][Ss][Ee]
					|
					[Uu][Nn][Ll][Ee][Ss][Ss]
				)
				(?: \s+ ([\w.-]+) )?
				\s*
				\Q$BLOCK_END_TAG\E
			|
				\Q$INCLUDE_START_TAG\E		
				\s*
				([Ii][Nn][Cc][Ll][Uu][Dd][Ee])\s+
				(?: "([^"]*?)" | '([^']*?)' | (\S*?) )
				\s*
				\Q$INCLUDE_END_TAG\E
			)
			/sx;
			
	while ($$filedata =~ s/$regexp//sx) {

		$text  = $1;  # preceding text
		$tag   = $2;  # whole tag (needed for line count)
		$type  = $4 || $6;  # tag type (undef for var)
		$ident = defined $3 ? $3 : defined $5 ? $5 : defined $7 ? $7 : 
				 defined $8 ? $8 : defined $9 ? $9 : undef;
	
		# get line position
		$line += ($text =~ tr/\n//);
		
		if ($CHOMP) {
			# delete newline after last block tag
			$space ? $text =~ s/^[ \t]*\r?\n// : $text =~ s/^[ \t]*\r?\n/ / if $block;
			
			# check this tag is not a var or include
			$block = $type && $type !~ /^[Ii]/ ? 1 : 0;
			$space = 0; # no space was added (default)
			
			# remove newline preceding this block tag
			$space = 1 if $block && $text =~ s/\r?\n[ \t]*\z/ /;
		}
		
		# the first element of the @pstacks array contains a reference
		# to the current parse stack where the template data is added.
		
		push @{$pstacks[0]}, [ TEXT, $text ] if defined $text;

		if (!defined $type) {
		
			push @{$pstacks[0]}, [ VAR, $ident ];
			
		} elsif ($type =~ /^[Bb]/) {
		
			croak("Parse error: invalid param in block tag at $filename line $line") 
				unless length $ident;
		
			# create a new parse stack were all data 
			# will be added until the block ends.
			unshift @pstacks, [];
			
			# create a reference to this new parse stack in the old one
			# so the block data doesn't get lost after the block ends.
			push @{$pstacks[1]}, [ BLOCK, $ident, $pstacks[0] ];
			
			# add block type and ident for syntax checking
			unshift @idents, [ 'BEGIN', $ident ];
			
		} elsif ($type =~ /^[Ee][Nn]/) {
			
			croak("Parse error: block closed but never opened at $filename line $line")
				if scalar @idents == 0;

			croak("Parse error: invalid param in block tag at $filename line $line")
				if defined $ident && (uc $ident eq 'BEGIN' || uc $ident ne $idents[0]->[TYPE])
				&& $ident ne $idents[0]->[IDENT];
			
			shift @pstacks;
			shift @idents;
			
		} elsif ($type =~ /^[Ii][Ff]/) {
		
			croak("Parse error: invalid param in if tag at $filename line $line") 
				unless length $ident;
		
			unshift  @pstacks,       [];
			push     @{$pstacks[1]}, [  IF , $ident, $pstacks[0] ];
			unshift  @idents,        [ 'IF', $ident ];
	
		} elsif ($type =~ /^[Uu]/) {
		
			croak("Parse error: invalid param in unless tag at $filename line $line")
				unless length $ident;
		
			unshift  @pstacks,       [];
			push     @{$pstacks[1]}, [  UNLESS , $ident, $pstacks[0] ];
			unshift  @idents,        [ 'UNLESS', $ident ];
			
		} elsif ($type =~ /^[Ee]/) {

			croak("Parse error: found else tag with no matching block at $filename line $line")
				if scalar @idents == 0;
				
			croak("Parse error: invalid param in else tag at $filename line $line")
				if defined $ident && $ident ne $idents[0]->[IDENT];
		
			shift   @pstacks;       # close current block
			unshift @pstacks, [];   # and create a new one.
			push    @{$pstacks[1]}, [ ELSE, undef, $pstacks[0] ];
		
		} elsif ($type =~ /^[Ii]/) {
		
			croak("Parse error: file to include not defined at $filename line $line") 
				unless length $ident;
		
			push @{$pstacks[0]}, [ FILE, $ident ];
			
		} elsif ($type =~ /^[Ll]/) {
		
			croak("Parse error: invalid param in loop tag at $filename line $line") 
				unless length $ident;

			unshift  @pstacks,       [];
			push     @{$pstacks[1]}, [  LOOP , $ident, $pstacks[0] ];
			unshift  @idents,        [ 'LOOP', $ident ];

		}

		# tag might contain newline
		$line += ($tag =~ tr/\n//);

	}

	# chomp and add remaining text not recognized by the regexp
	$$filedata =~ s/^[ \t]*\n// if $CHOMP && $block; 
	push @{$pstacks[0]}, [ TEXT, $$filedata ];

	croak("Parse error: block not closed at $filename")
		if @idents > 0;

	return $pstacks[0];

}


sub _output {

	my $self = shift;
	my $stack = shift;
	my ($line, $looped);
	
	foreach $line (@$stack) { # create template output
		$line->[TYPE] == VAR    ? $self->{'output'} .= $self->_value( $line->[IDENT] ) :
		$line->[TYPE] == TEXT   ? $self->{'output'} .= $line->[IDENT] :
		$line->[TYPE] == FILE   ? $self->_include( $line->[IDENT] )   :
		$line->[TYPE] == BLOCK  ? $looped = $self->_loop( $line->[IDENT], $line->[STACK], BLOCK )  :
		$line->[TYPE] == IF     ? $looped = $self->_loop( $line->[IDENT], $line->[STACK], IF )     :
		$line->[TYPE] == LOOP   ? $looped = $self->_loop( $line->[IDENT], $line->[STACK], LOOP )   :
		$line->[TYPE] == UNLESS ? $looped = $self->_loop( $line->[IDENT], $line->[STACK], UNLESS ) :
		$line->[TYPE] == ELSE   ? $looped = $self->_loop( $looped, $line->[STACK], ELSE ) : next;
	}

}


sub _value {

	my $self  = shift;
	my $ident = shift;
	my $value = $self->_get($ident);
	
	unless (defined $value) {
		croak("No value found for variable $ident at " . $self->{'files'}->[0]->[NAME])
			if $self->{'config'}->{'strict'};
		return ''; # no strict
	}

	# if the value is a code reference the code
	# is called and the output is returned
	
	if (ref $value) {
		$value = &{$value} if ref $value eq 'CODE';
		return '' if !defined $value || ref $value;
	}

	if ($self->{'config'}->{'parse_vars'}) {
		$value =~ s/ # replace template vars
			\Q$VAR_START_TAG\E
			\s*([\w.-]+)\s*
			\Q$VAR_END_TAG\E
		/ $self->_value($1) /xge;
	}

	return $value;

}


sub _loop {

	my $self  = shift;
	my $ident = shift;
	my $stack = shift;
	my $mode  = shift;
	my ($data, $vars, $skip);
	my $loop_vars  = 0;
	my $loop_count = 0;

	if ($mode == BLOCK) {
	
		$data = $self->_get($ident);
		return 0 unless defined $data;
		
		# no array reference: check the Boolean 
		# context to loop once or skip the block
		unless (ref $data eq 'ARRAY') {
			$data ? $data = [1] : return 0;
			# if statement: no loop vars 
		} else {
			return 0 unless @$data;
			$loop_vars = $self->{'config'}->{'loop_vars'};
		}
	
	} elsif ($mode == LOOP) {

		$data = $self->_get($ident);
		return 0 unless defined $data;
		return 0 unless ref $data eq 'ARRAY';
		return 0 unless @$data;
		$loop_vars = $self->{'config'}->{'loop_vars'};

	} elsif ($mode == IF) {
	
		$data = $self->_get($ident);
		return 0 unless defined $data;
		$data ? $data = [1] : return 0;
	
	} elsif ($mode == UNLESS) {
	
		$data = $self->_get($ident);
		return 0 if $data;
		$data = [1];
	
	} elsif ($mode == ELSE) {
	
		return 0 if $ident;
		$data = [1];
	
	}
	
	foreach $vars (@$data) {
	
		ref $vars eq 'HASH' # add current loop variables
			? (unshift @{ $self->{'vars'} }, $vars)
			: ($skip = 1);

		if ($loop_vars) {
			++$loop_count;
			
			# add loop context variables
			@$data == 1 ? unshift @{ $self->{'loop'} }, { %$FIRST, %$LAST } :
			$loop_count == 1 ? unshift @{ $self->{'loop'} }, $FIRST :
			$loop_count == @$data ? unshift @{ $self->{'loop'} }, $LAST :
				unshift @{ $self->{'loop'} }, $INNER;
			
			# create output
			$self->_output($stack);

			# delete loop context variables
			shift @{ $self->{'loop'} };
			
		} else {
		
			# create output
			$self->_output($stack);
		
		}

		!$skip # delete current loop variables
			? (shift @{ $self->{'vars'} })
			: ($skip = 0);
	}

	return 1;
}


sub _get {
# - returns the variable value from the variable
#   hash (considering the temporary loop variables)

	my $self  = shift;
	my (@ident, $root, $last_key, $skip);
	
	@ident = split /\./, $_[0];
	$last_key = pop @ident;
	
	# check for loop context variables
	return $self->{'loop'}->[0]->{$last_key} if $self->{'config'}->{'loop_vars'}
		&& @ident == 0 && exists $self->{'loop'}->[0]->{$last_key};
	
	# loop values are prepended to the front of the 
	# var array so start with them first
	
	foreach my $hash (@{ $self->{'vars'} }) {

		# speed up normal variable lookup
		return $hash->{$last_key} if @ident == 0 
			&& exists $hash->{$last_key};

		$root = $hash;	# do not change the hash

		foreach my $key (@ident) {
		
			if (ref $root eq 'HASH') {
			# go down the hash structure
			$root = $root->{$key};
			}
			
			else {
			# nothing found
			$skip = 1; last;
			}
			
		}
	
		unless ($skip) { # return if found something
		return $root->{$last_key} if exists $root->{$last_key};
		}
		
		else { # try again
		$skip = 0;
		}

	}

	return undef;

}


sub print {

	my $self = shift;
	my $fh = shift;

	ref $fh eq 'GLOB' || ref \$fh eq 'GLOB'
		? CORE::print $fh $self->{'output'}
		: CORE::print $self->{'output'};

	return 1;

}


sub fetch {
	my $self = shift;
	my $temp = $self->{'output'};
	return \$temp;
}


sub clear {
	my $self = shift;
	$self->clear_vars();
	$self->clear_out();
	return 1;
}


sub clear_vars {
	my $self = shift;
	$self->{'vars'} = [{}];
	$self->block();
	return 1;
}


sub clear_out {
	my $self = shift;
	$self->{'output'} = '';
	return 1;
}


sub clear_cache {
	$CACHE = {};
	return 1;
}


1;



=head1 NAME

HTML::KTemplate - Perl module to process HTML templates.


=head1 SYNOPSIS

B<CGI-Script:>

  #!/usr/bin/perl -w
  use HTML::KTemplate;
  
  $tpl = HTML::KTemplate->new('path/to/templates');
  
  $tpl->assign( TITLE  => 'Template Test Page'    );
  $tpl->assign( TEXT   => 'Some welcome text ...' );
  
  foreach (1 .. 3) {
  
      $tpl->assign( LOOP,
          TEXT => 'Just a test ...',
      );
  
  }
  
  $tpl->process('template.tpl');
  
  $tpl->print();

B<Template:>

  <html>
  <head><title>[% TITLE %]</title>
  <body>
  
  Hello! [% TEXT %]<p>
  
  <!-- BEGIN LOOP -->  
  
  [% TEXT %]<br>
  
  <!-- END LOOP -->
  
  </body>
  </html>


B<Output:>

  Hello! Some welcome text ...
  
  Just a test ...
  Just a test ...
  Just a test ...


=head1 MOTIVATION

Although there are many different template modules at CPAN, I couldn't find any that would meet my expectations. So I created this one with following features:

=over 4

=item *
Template syntax can consist only of variables and blocks.

=item *
Support for multidimensional data structures.

=item *
Everything is very simple and very fast.

=item *
Still there are many advanced options available.

=back

Please email me any comments, suggestions or bug reports to <kasper@repsak.de>.


=head1 VARIABLES

By default, template variables are embedded within C<[% %]> and may contain any alphanumeric characters including the underscore and the hyphen. The values for the variables are assigned with C<assign()>, passed as a hash or a hash reference.

  %hash = (
      VARIABLE => 'Value',
  );
  
  $tpl->assign( %hash );
  $tpl->assign(\%hash );
  $tpl->assign( VARIABLE => 'Value' );

To access a multidimensional hash data structure, the variable names are separated by a dot. In the following example, two values for the variables C<[% USER.NAME %]> and C<[% USER.EMAIL %]> are assigned:

  $tpl->assign(
  
      USER => {
          NAME  => 'Kasper Dziurdz',     # [% USER.NAME %]
          EMAIL => 'kasper@repsak.de',   # [% USER.EMAIL %]
      },
      
  );

If the value of a variable is a reference to a subroutine, the subroutine is called and the returned string is included in the output. This is the only way to execute Perl code in a template.

  $tpl->assign(
  
      BENCHMARK => sub {
          # get benchmark data
          return 'created in 0.01 seconds';
      }
  
  );


=head1 BLOCKS

Blocks allow you to create loops and iterate over a part of a template or to write simple if-statements. A block begins with C<< <!-- BEGIN BLOCKNAME --> >> and ends with C<< <!-- END BLOCKNAME --> >>. This is an example of creating a block with the C<block()> method:

  $tpl->assign( HEADER  => 'Some numbers:' );
  
  @block_values = ('One', 'Two', 'Three', 'Four');
  
  foreach (@block_values) {
  
      $tpl->block('LOOP_NUMBERS');
      $tpl->assign( NUMBER    => $_ );
      $tpl->assign( SOMETHING => '' );
  
  }
  
  $tpl->block();  # leave block
  
  $tpl->assign( FOOTER => '...in words.' );

Each time C<block()> is called it creates a new loop in the selected block. All variable values passed to C<assign()> are assigned only to this loop until a new loop is created or C<block()> is called without any arguments to assign global variables again. This is a template for the script above:

  [% HEADER %]
  
  <!-- BEGIN LOOP_NUMBERS -->
  
    [% NUMBER %]
  
  <!-- END LOOP_NUMBERS -->
  
  [% FOOTER %]

Global variables (or outer block variables) are also available inside a block. However, if there is a block variable with the same name, the block variable is preferred.

Because a block is a normal variable with an array reference, blocks can also be created without the C<block()> method:

  $tpl->assign( 
      HEADER  => 'Some numbers:',
      LOOP_NUMBERS => 
          [
              { NUMBER => 'One'   },
              { NUMBER => 'Two'   },
              { NUMBER => 'Three' },
              { NUMBER => 'Four'  },
          ],
      FOOTER => '...in words.',
  );

Loops within loops work as you would expect. To create a nested loop with C<block()>, you have to pass all block names separate as a list or joined with a dot, for example as C<BLOCK_1.BLOCK_2>. This way, a new loop for C<BLOCK_2> is created in the last loop of C<BLOCK_1>. The variable values are assigned with C<assign()>.

  foreach (@block_one) {
  
      $tpl->block('BLOCK_1');
      $tpl->assign(VAR => $_);
  
      foreach (@block_two) {
  
          $tpl->block('BLOCK_1', 'BLOCK_2');
          $tpl->assign(VAR => $_);
  
      }
  }
  
  $tpl->block();  # leave block

The template would look like this:

  <!-- BEGIN BLOCK_1 -->
  
      <!-- BEGIN BLOCK_2 -->
  
      <!-- END BLOCK_2 -->
  
  <!-- END BLOCK_1 -->

B<Important: You have to call C<block()> without any arguments to assign global variables again.>

It is also possible to create a loop with the C<assign()> method by passing the block name as the first argument (or all block names joined with a dot to create nested loops). The variables can be assigned only once and not as a hash reference but there is no need to use the C<block()> method.

  $tpl->assign( BLOCK,  # assign to this block
      VARIABLE_1 => 'Block ...',
      VARIABLE_2 => 'Block ...',
  );
  
  $tpl->assign(  # assign global again
      VARIABLE_3 => 'Global ...'.
  );

Blocks can even be used to create if-statements. Simply assign a variable with a true or false value. Based on that, the block is skipped or included in the output. 

  $tpl->assign( SHOW_INFO  => 1 );  # show block SHOW_INFO
  $tpl->assign( SHOW_LOGIN => 0 );  # skip block SHOW_LOGIN

For a better control of the loop output, three special loop variables can be made available inside a loop: C<FIRST>, C<INNER> and C<LAST>. This variables are disabled by default (see L<OPTIONS|"Loop Vars"> section how to enable them).

  <!-- BEGIN LOOP -->
  
  
      <!-- BEGIN FIRST -->
       First loop pass
      <!-- END FIRST -->
  
  
      <!-- BEGIN INNER -->
       Neither first nor last
      <!-- END INNER -->
  
  
      <!-- BEGIN LAST -->
       Last loop pass
      <!-- END LAST -->
  
  
  <!-- END LOOP -->


=head1 INCLUDES

Includes are used to process and include the output of another template file directly into the current template in place of the include tag. All variables and blocks assigned to the current template are also available inside the included template.

  <!-- INCLUDE file.tpl -->
  
  <!-- INCLUDE "file.tpl" -->
  
  <!-- INCLUDE 'file.tpl' -->

If the template can't be found under the specified file path (considering the root path), the path to the enclosing file is tried. See L<OPTIONS|"No Includes"> section how to disable includes or change the limit for recursive includes. 

It is possible to include template files defined by a variable when the option for including variables is enabled (it is disabled by default).

  <!-- INCLUDE VARIABLE -->


=head1 ADVANCED

Although it is possible to create loops and if statements with the block tag, sometimes the template syntax might get too confusing or not allow to write the wanted conditions in an easy way. For this reason if, unless, else and loop tags are available.

  <!-- IF VARIABLE -->
  
  <!-- END VARIABLE -->
   
   
  <!-- UNLESS VARIABLE -->
 
  <!-- END VARIABLE -->
   
   
  <!-- LOOP ARRAY -->
  
  <!-- END ARRAY -->
   
   
  <!-- IF VARIABLE -->
  
  <!-- ELSE VARIABLE -->
  
  <!-- END VARIABLE -->

The else tag can be used with all statements, even with loops. For an even cleaner template syntax, the else and the end tag can be written without the variable name.

  <!-- BEGIN ARRAY -->
  
  <!-- END -->
   
   
  <!-- IF VARIABLE -->
  
  <!-- ELSE -->
  
  <!-- END -->

The following syntax is also allowed but will not work with the block tag:

  <!-- IF VARIABLE -->
  
  <!-- ELSE -->
  
  <!-- END IF -->
   
   
  <!-- LOOP ARRAY -->
  
  <!-- END LOOP -->


=head1 METHODS

=head2 new()

Creates a new template object.

  $tpl = HTML::KTemplate->new();
  
  $tpl = HTML::KTemplate->new('/path/to/templates');
  
  $tpl = HTML::KTemplate->new( 
      root         => '/path/to/templates',
      cache        => 0,
      strict       => 0,
      no_includes  => 0,
      max_includes => 15,
      loop_vars    => 0,
      blind_cache  => 0,
      include_vars => 0,
      parse_vars   => 0,
  );


=head2 assign()

Assigns values for the variables used in the template.

  %hash = (
      VARIABLE => 'Value',
  );
  
  $tpl->assign( %hash );
  $tpl->assign(\%hash );
  $tpl->assign( VARIABLE => 'Value' ); 
    
  $tpl->assign( BLOCK,
      VARIABLE => 'Value',
      VARIABLE => 'Value',
  );

=head2 block()

See the description of L<BLOCKS|"BLOCKS">.

  $tpl->block('BLOCK_1');
  
  $tpl->block('BLOCK_1','BLOCK_2');
  $tpl->block('BLOCK_1.BLOCK_2');
  
  $tpl->block();  # leave block

=head2 process()

The C<process()> method is called to process the template files passed as arguments. It loads each template file, parses it and adds it to the template output. It is also possible to pass a reference to a scalar, array or file handle to initialize the template from memory. The use of the template output is determined by the C<print()> or the C<fetch()> method. 

  $tpl->process('header.tpl', 'footer.tpl');
  
  $tpl->process('header.tpl');
  $tpl->process('footer.tpl');
  
  $tpl->process(\$scalar);
  $tpl->process(\@array);
  $tpl->process(\*FH);

=head2 print()

Prints the output data to C<STDOUT>. If a file handle reference is passed, it is used instead of the standard output.

  $tpl->print();
  
  $tpl->print(\*FILE);

=head2 fetch()

Returns a scalar reference to the output data. 

  $output_ref = $tpl->fetch();
  
  print FILE $$output_ref;

=head2 clear()

Clears all variable values and other data being held in memory (except cache data). 

  $tpl->clear();

Equivalent to:

  $tpl->clear_vars();
  $tpl->clear_out();

=head2 clear_vars()

Clears all assigned variable values.

  $tpl->clear_vars();

=head2 clear_out()

Clears all output data created by C<process()>.

  $tpl->clear_out();

=head2 clear_cache()

Empties all cache data.

  $tpl->clear_cache();


=head1 OPTIONS

=head2 Variable Tag

  $HTML::KTemplate::VAR_START_TAG = '[%';
  $HTML::KTemplate::VAR_END_TAG   = '%]';

=head2 Block Tag

  $HTML::KTemplate::BLOCK_START_TAG = '<!--';
  $HTML::KTemplate::BLOCK_END_TAG   = '-->';

=head2 Include Tag

  $HTML::KTemplate::INCLUDE_START_TAG = '<!--';
  $HTML::KTemplate::INCLUDE_END_TAG   = '-->';

=head2 Root

  $HTML::KTemplate::ROOT = undef;  # default
  $HTML::KTemplate::ROOT = '/path/to/templates';
  
  $tpl = HTML::KTemplate->new( '/path/to/templates' );
  $tpl = HTML::KTemplate->new( root => '/path/to/templates' );

=head2 No Includes

Set this option to 1 to disable includes. The include tags will be skipped unless the strict option is set to 1.

  $tpl = HTML::KTemplate->new( no_includes => 0 );  # default
  $tpl = HTML::KTemplate->new( no_includes => 1 );

=head2 Max Includes

Allows to set the maximum depth that includes can reach. An error is raised when this depth is exceeded.

  $tpl = HTML::KTemplate->new( max_includes => 15 );  # default

=head2 Include Vars

Allows to include template files defined by a variable (see the description of L<INCLUDES|"INCLUDES"> for more information).

  $tpl = HTML::KTemplate->new( include_vars => 0 );  # default
  $tpl = HTML::KTemplate->new( include_vars => 1 );

=head2 Cache

Caching option for a persistent environment like mod_perl. Parsed templates will be cached in memory based on their file path and modification date. Use C<clear_cache()> to empty cache.

  $tpl = HTML::KTemplate->new( cache => 0 );  # default
  $tpl = HTML::KTemplate->new( cache => 1 );

=head2 Blind Cache

Behaves as the normal caching option but does not check the modification date to see if the template has changed. This might result in some speed improvement over normal caching.

  $tpl = HTML::KTemplate->new( blind_cache => 0 );  # default
  $tpl = HTML::KTemplate->new( blind_cache => 1 );

=head2 Loop Vars

Set this option to 1 to enable the loop variables C<FIRST>, C<INNER> and C<LAST>.

  $tpl = HTML::KTemplate->new( loop_vars => 0 );  # default
  $tpl = HTML::KTemplate->new( loop_vars => 1 );

The default loop variables can be changed in the following way:

  $HTML::KTemplate::FIRST = { 'FIRST' => 1, 'first' => 1 };
  $HTML::KTemplate::INNER = { 'INNER' => 1, 'inner' => 1 };
  $HTML::KTemplate::LAST  = { 'LAST'  => 1, 'last'  => 1 };

=head2 Parse Vars

Set this option to 1 to parse variables. That way all template variables inside of a variable will be replaced with their assigned values.

  $tpl = HTML::KTemplate->new( parse_vars => 0 );  # default
  $tpl = HTML::KTemplate->new( parse_vars => 1 );


=head2 Strict

Set this option to 1 to raise errors on not defined variables and include tags when disabled.

  $tpl = HTML::KTemplate->new( strict => 0 );  # default
  $tpl = HTML::KTemplate->new( strict => 1 );

=head2 Chomp

Removes the newline before and after a block tag.

  $HTML::KTemplate::CHOMP = 1;  # default
  $HTML::KTemplate::CHOMP = 0;


=head1 MAILING LIST

If you want to get email when a new version of HTML::KTemplate is released, join the announcements mailing list:

  http://lists.sourceforge.net/lists/listinfo/html-ktemplate-announce

A mailing list for discussing HTML::KTemplate is available at <html-ktemplate-users@lists.sourceforge.net>. To join, visit:

  http://lists.sourceforge.net/lists/listinfo/html-ktemplate-users

You can also email me questions, comments, suggestions or bug reports directly to <kasper@repsak.de>.


=head1 WEBSITE

More information about HTML::KTemplate can be found at:

  http://html-ktemplate.sourceforge.net/


=head1 COPYRIGHT

  Copyright (c) 2002-2003 Kasper Dziurdz. All rights reserved.
  
  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  Artistic License for more details.

=head1 AUTHOR

Kasper Dziurdz <kasper@repsak.de>

=cut

