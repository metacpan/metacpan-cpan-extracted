# This code is part of Perl distribution HTML-FromMail version 3.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package HTML::FromMail;{
our $VERSION = '3.01';
}

use base 'Mail::Reporter';

use strict;
use warnings;

use File::Spec::Functions;
use File::Basename qw/basename dirname/;

my %default_producers = ( # classes will be compiled automatically when used
	'Mail::Message'        => 'HTML::FromMail::Message',
	'Mail::Message::Head'  => 'HTML::FromMail::Head',
	'Mail::Message::Field' => 'HTML::FromMail::Field',
);

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args) or return;

	# Defining the formatter to be used
	my $form = $args->{formatter} || {};
	if(!ref $form)
	{	eval "require $form";
		die "ERROR: Formatter $form can not be used:\n$@" if $@;
		$form = $form->new;
	}
	elsif(ref $form eq 'HASH')
	{	require HTML::FromMail::Format::OODoc;
		$form = HTML::FromMail::Format::OODoc->new(%$form);
	}

	die "ERROR: Formatter $form could not be instantiated\n"
		unless defined $form;

	$self->{HF_formatter} = $form;

	# Defining the producers
	my %prod = %default_producers;   # copy
	my $prod = $args->{producers} || {};
	@prod{ keys %$prod } = values %$prod;
	while( my($class, $impl) = each %prod)
	{	$self->producer($class, $impl);
	}

	# Collect the settings
	my $settings = $args->{settings} || {};
	while( my ($topic, $defaults) = each %$settings)
	{	$self->settings($topic, $defaults);
	}

	$self->{HF_templates} = $args->{templates} || '.';
	$self;
}

#--------------------

sub formatter() { $_[0]->{HF_formatter} }

#-----------


sub producer($;$)
{	my ($self, $thing) = (shift, shift);
	my $class = ref $thing || $thing;

	return ($self->{HF_producer}{$class} = shift) if @_;
	if(my $prod = $self->{HF_producer}{$class})
	{	eval "require $prod";
		$@ and $self->log(ERROR => "Cannot use $prod for $class:\n$@"), return undef;

		return $prod->new;
	}

	# Look for producer in the inheritance structure
	no strict 'refs';
	foreach ( @{"$class\::ISA"} )
	{	my $prod = $self->producer($_);
		return $prod if defined $prod;
	}

	undef;
}


sub templates(;$)
{	my $self = shift;
	return $self->{HF_templates} unless @_;

	my $topic    = ref $_[0] ? shift->topic : shift;
	my $templates= $self->{HF_templates};

	my $filename = catfile($templates, $topic);
	return $filename if -f $filename;

	my $dirname  = catdir($templates, $topic);
	return $dirname if -d $dirname;

	$self->log(ERROR => "Cannot find template file or directory '$topic' in '$templates'.\n");
	undef;
}


sub settings($;@)
{	my $self  = shift;
	my $topic = ref $_[0] ? shift->topic : shift;
	@_ or return $self->{HF_settings}{$topic};

	$self->{HF_settings}{$topic} = @_ == 1 ? shift : +{ @_ };
}


sub export($@)
{	my ($self, $object, %args) = @_;

	my $producer  = $self->producer($object)
		or $self->log(ERROR => "No producer for ",ref($object), " objects."), return;

	my $output    = $args{output}
		or $self->log(ERROR => "No output directory or file specified."), return;

# this cannot be right when $output isa filename?
#   $self->log(ERROR => "Cannot create output directory $output: $!"), return
#      unless -d $output || mkdir $output;

	my $topic     = $producer->topic;
	my @files;
	if(my $input = $args{use})
	{	# some template files are explicitly named
		my $templates = $self->templates;

		foreach my $in (ref $input ? @$input : $input)
		{	my $fn = file_name_is_absolute($in) ? $in : catfile($templates, $in);

			-f $fn or $self->log(WARNING => "No template file $fn"), next;

			push @files, $fn;
		}
	}
	else
	{	my $templates = $self->templates($topic)
			or $self->log(WARNING => "No templates for $topic objects."), return;

		@files = $self->expandFiles($templates);
		@files or $self->log(WARNING => "No templates found in $templates directory.");
	}

	my $formatter = $self->formatter(settings => $self->{HF_settings});
	my @outfiles;

	foreach my $infile (@files)
	{	my $basename = basename $infile;
		my $outfile  = catfile($output, $basename);
		push @outfiles, $outfile;

		$formatter->export(
			%args,
			object   => $object,   input     => $infile,
			producer => $producer, formatter => $formatter,
			output   => $outfile,  outdir    => $output,
			main     => $self,
		);
	}

	$outfiles[0];
}


sub expandFiles($)
{	my ($self, $thing) = @_;
	return @$thing if ref $thing eq 'ARRAY';
	return $thing  if -f $thing;

	-d $thing
		or $self->log(WARNING => "Cannot find $thing"), return ();

	opendir DIR, $thing
		or $self->log(ERROR => "Cannot read from directory $thing: $!"), return ();

	my @files;
	while(my $item = readdir DIR)
	{	next if $item eq '.' || $item eq '..';

		my $full = catfile $thing, $item;
		if(-f $full)
		{	push @files, $full;
			next;
		}

		$full    = catdir $thing, $item;
		if(-d $full)
		{	push @files, $self->expandFiles($full);
			next;
		}

		$self->log(WARNING => "Skipping $full, which is neither file or directory.");
	}

	closedir DIR;
	@files;
}

#--------------------

1;
