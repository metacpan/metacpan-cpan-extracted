package IO::StructuredOutput::Styles;

use 5.00503;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

use Carp qw(croak);
use Text::CSV_XS;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use test1 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);

$VERSION = sprintf "%d.%03d", q$Revision: 1.8 $ =~ /(\d+)/g;

# Preloaded methods go here.

sub addstyle
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $attr = shift;

	my $self;
	$self->{format} = $attr->{format} || 'html';
	$self->{wbformat} = $attr->{wbformat};
	$self->{wb} = $attr->{wb};

	# make our new object
	bless $self, $class;
}
sub modify
{
	ref(my $self = shift) or croak "instance variable needed";
	my $info = shift;

	my %allowed_formats = (
		font	=> 1,
		size	=> 1,
		color	=> 1,
		bold	=> 1,
		italic	=> 1,
		underline	=> 1,
		num_format	=> 1,
		align	=> 1,
		valign	=> 1,
		text_wrap	=> 1,
		bg_color	=> 1,
		border	=> 1,
		num_format	=> 1,
		);

	# do bool's
	if (defined($info->{bold})) {
		my $bold = $info->{bold} ? 1 : 0;
		$self->{attr}{bold} = $bold;
	}
	if (defined($info->{italic})) {
		my $italic = $info->{italic} ? 1 : 0;
		$self->{attr}{italic} = $italic;
	}
	if (defined($info->{color}))
	{
		if ($info->{color} =~ /^(\d+)(#......)/)
		{	# got an indexed color
			my $index = $1;
			my $hex = $2;
			if ($self->{format} eq 'xls')
			{
				$self->{wb}->set_custom_color($index,$hex);
				$info->{color} = $index;
			} else {
				$info->{color} = $hex;
			}
		} else {
			# assume we got a word like 'white'
		}
	}
	if (defined($info->{bg_color}))
	{
		if ($info->{bg_color} =~ /^(\d+)(#......)/)
		{
			my $index = $1;
			my $hex = $2;
			if ($self->{format} eq 'xls')
			{
				$self->{wb}->set_custom_color($index,$hex);
				$info->{bg_color} = $index;
			} else {
				$info->{bg_color} = $hex;
			}
		} else {
			# assume we got a word like 'white'
		}
	}
	foreach my $key (keys %{$info})
	{
		$self->{attr}{$key} = $info->{$key} if $allowed_formats{$key};
	}
	if ($self->{format} eq 'xls')
	{	# need to use the xls format object
		$self->{wbformat}->set_properties(%{$self->{attr}});
	}
	return;
}
sub output_style
{
	ref(my $self = shift) or croak "instance variable needed";
	my $format = $self->{format};
	if ($format eq 'html')
	{
		my $data = shift;
		my $colspan = shift;
		my $rv = "<TD ";
		$rv .= "COLSPAN=\"$colspan\" " if $colspan;
		$rv .= "ALIGN=\"$self->{attr}{align}\" " if $self->{attr}{align};
		$rv .= "VALIGN=\"$self->{attr}{valign}\" " if $self->{attr}{valign};
		$rv .= "BGCOLOR=\"$self->{attr}{bg_color}\" " if $self->{attr}{bg_color};
		$rv .= "><FONT COLOR=\"$self->{attr}{color}\" " if $self->{attr}{color};
		$rv .= "><FONT FACE=\"$self->{attr}{font}\" " if $self->{attr}{font};
		$rv .= "><FONT SIZE=\"$self->{attr}{font}\" " if $self->{attr}{size};
		$rv .= "><B " if $self->{attr}{bold};
		$rv .= "><I " if $self->{attr}{italic};
		$rv .= "><U " if $self->{attr}{underline};
		$rv .= ">$data<";
		$rv .= "/U><" if $self->{attr}{underline};
		$rv .= "/I><" if $self->{attr}{italic};
		$rv .= "/B><" if $self->{attr}{bold};
		$rv .= "/FONT><" if $self->{attr}{size};
		$rv .= "/FONT><" if $self->{attr}{font};
		$rv .= "/FONT><" if $self->{attr}{color};
		$rv .= "/TD>\n";
		return $rv;
	} elsif ($format eq 'xls') {
		return $self->{wbformat};
	} elsif ($format eq 'csv') {
		return; # no style'ing available in this format
	}
}



1;
__END__

=head1 NAME

Styles - Perl extension to IO::StructuredData to handle styles (display properties) in an IO::STructuredOutput object.

=head1 SYNOPSIS

  use IO::StructuredOutput::Styles;

  ### See IO::StructuredOutput for details

=head1 DESCRIPTION

This class implements objects to create and manipulate styles for IO::StructuredOutput objects.

=head2 EXPORT

None by default.

=head1 SEE ALSO

IO::StructuredOutput

=head1 AUTHOR

Joshua I. Miller E<lt>jmiller@purifieddata.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Joshua I. Miller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
