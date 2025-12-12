# This code is part of Perl distribution HTML-FromMail version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package HTML::FromMail;{
our $VERSION = '4.00';
}

use base 'Mail::Reporter';

use strict;
use warnings;

use Log::Report 'html-frommail';

use File::Spec::Functions qw/catfile catdir file_name_is_absolute/;
use File::Basename        qw/basename dirname/;

my %default_producers = ( # classes will be compiled automatically when used
	'Mail::Message'        => 'HTML::FromMail::Message',
	'Mail::Message::Head'  => 'HTML::FromMail::Head',
	'Mail::Message::Field' => 'HTML::FromMail::Field',
);

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	# Defining the formatter to be used
	my $form = $args->{formatter} || {};
	if(!ref $form)
	{	eval "require $form";
		$@ and panic "Formatter $form can not be used:\n$@";
		$form = $form->new;
	}
	elsif(ref $form eq 'HASH')
	{	require HTML::FromMail::Format::OODoc;
		$form = HTML::FromMail::Format::OODoc->new(%$form);
	}

	defined $form
		or error __x"formatter {class} could not be instantiated.", class => $form;

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
		$@ and error __x"cannot use {producer} for {class}:\n$@", producer => $prod, class => $class, error => $@;
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

	my $topic    = blessed $_[0] ? shift->topic : shift;
	my $templates= $self->{HF_templates};

	my $filename = catfile $templates, $topic;
	return $filename if -f $filename;

	my $dirname  = catdir $templates, $topic;
	return $dirname if -d $dirname;

	error __x"cannot find template file or directory '{topic}' in '{directory}'.",
		topic => $topic, directory => $templates;
}


sub settings($;@)
{	my $self  = shift;
	my $topic = blessed $_[0] ? shift->topic : shift;
	@_ or return $self->{HF_settings}{$topic};

	$self->{HF_settings}{$topic} = @_ == 1 ? shift : +{ @_ };
}


sub export($@)
{	my ($self, $object, %args) = @_;

	my $producer  = $self->producer($object)
		or error __x"no producer for {class} objects.", class => ref $object;

	my $output    = $args{output}
		or error __x"no output directory or file specified.";

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
			-f $fn or warning(__x"no template file {file}.", file => $fn), next;

			push @files, $fn;
		}
	}
	else
	{	my $templates = $self->templates($topic)
			or warning(__x"no templates for {topic} objects.", topic => $topic), return;

		@files = $self->expandFiles($templates);
		@files or warning __x"no templates found in {dir} directory.", dir => $templates;
	}

	my $formatter = $self->formatter(settings => $self->{HF_settings});
	my @outfiles;

	foreach my $infile (@files)
	{	my $basename = basename $infile;
		my $outfile  = catfile $output, $basename;
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
		or warning(__x"cannot find directory {dir}.", dir => $thing), return ();

	opendir DIR, $thing
		or fault __x"cannot read from directory {dir}", dir => $thing;

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

		warning __x"skipping {name}, which is neither file or directory.", name => $full;
	}

	closedir DIR;
	@files;
}

#--------------------

1;
