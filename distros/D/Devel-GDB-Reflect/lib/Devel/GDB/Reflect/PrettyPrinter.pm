package Devel::GDB::Reflect::PrettyPrinter;

use warnings;
use strict;

our $PAD = " " x 4;

sub new($;$$$$)
{
	my $class = shift;
	my ($parent, $open_brace, $separator, $close_brace) = @_;

	defined($open_brace)  or $open_brace = "[";
	defined($separator)   or $separator = ",";
	defined($close_brace) or $close_brace = "]";

	# Add some space around the separator: ensure there's a space before it
	# (unless it's a comma or semicolon), and a space after it
	$separator =~ s/^([^\s,;])/ $1/;
	$separator =~ s/([^\s])$/$1 /;

	my $self = bless
		{
			q           => [],
			first       => 1,
			fh          => \do { local *FH },
			open_brace  => $open_brace,
			close_brace => $close_brace,
			separator   => $separator,
		};

	if(defined $parent)
	{
		$self->{parent} = $parent;
	}
	else
	{
		$self->{raw_print} = sub { local $\ = local $, = ""; print @_ };
	}

	tie *{$self->{fh}}, $class, $self;

	return $self;
}

sub flush_queue
{
	my $self = shift;

	if($self->{q})
	{
		$self->{parent}->push("");
		$self->{parent}->print("$self->{open_brace}\n${PAD}")
			if $self->{open_brace} =~ /\S/;

		foreach(@{$self->{q}})
		{
			$self->{parent}->print("$self->{separator}\n${PAD}") unless $self->{first};
			$self->{parent}->print($_);
			$self->{first} = 0;
		}
	}

	undef $self->{q};
}

sub push
{
	my $self = shift;
	my ($text) = @_;

	return $self->{raw_print}->($text) if defined($self->{raw_print});

	if($text =~ /\n/)
	{
		$self->flush_queue();
	}

	if(defined $self->{q})
	{
		push @{$self->{q}}, @_;
	}
	else
	{
		$text =~ s/\n+$//;
		$text =~ s/\n/\n${PAD}/g;
		$self->{parent}->print("$self->{separator}\n${PAD}") unless $self->{first};
		$self->{parent}->print($text);

		$self->{first} = 0;
	}
}

sub print
{
	my $self = shift;
	my ($text) = @_;

	return $self->{raw_print}->($text) if defined($self->{raw_print});

	$self->flush_queue();

	$text =~ s/\n/\n${PAD}/g;
	$self->{parent}->print($text);
}

sub finish($;$)
{
	my $self = shift;
	my ($with_newline) = @_;

	return if defined($self->{raw_print});

	my $eol = $with_newline ? "\n" : "";

	if(defined $self->{q})
	{
		# Add space between open_brace, queue contents, and close_brace,
		# but only one space if the queue is empty.  No space if neither
		# open_brace nor close_brace contain any printing characters.

		my $sp = ("$self->{open_brace}$self->{close_brace}" =~ /\S/) ? " " : "";
		my $inner = @{$self->{q}} ? ($sp . join($self->{separator}, @{$self->{q}}) . $sp) : $sp;

		$self->{parent}->push($self->{open_brace} . $inner . $self->{close_brace} . $eol);
	}
	else
	{
		$self->{parent}->print("\n$self->{close_brace}")
			if $self->{close_brace} =~ /\S/;
	}
};

# Tiehandle interface
sub TIEHANDLE { $_[1] }
sub PRINT     { shift->push(@_) }
sub PRINTF    { shift->push(sprintf(shift, @_)) }

1
