=head1 NAME

HTML::Microformats::Datatype::RecurringDateTime - a datetime that recurs

=head1 SYNOPSIS

 my $r_datetime = HTML::Microformats::Datatype::RecurringDateTime->new($ical_string);
 print "$r_datetime\n";

=cut

package HTML::Microformats::Datatype::RecurringDateTime;

use HTML::Microformats::Utilities qw(searchClass stringify);
use base qw(HTML::Microformats::Datatype);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Datatype::DateTime;
use RDF::Trine;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Datatype::RecurringDateTime::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Datatype::RecurringDateTime::VERSION   = '0.105';
}

=head1 DESCRIPTION

=head2 Constructors

=over 4

=item C<< $r = HTML::Microformats::Datatype::RecurringDateTime->new($string, [$context]) >>

Creates a new HTML::Microformats::Datatype::RecurringDateTime object.

$string is an iCalendar-RRULE-style string.

=cut

sub new
{
	my $class   = shift;
	return $class->parse_string(@_) if @_;
	bless {}, $class;
}

=item C<< $r = HTML::Microformats::Datatype::RecurringDateTime->parse($string, $elem, $context) >>

Creates a new HTML::Microformats::Datatype::RecurringDateTime object.

$string is perhaps an iCalendar-RRULE-style string. $elem is the
XML::LibXML::Element being parsed. $context is the document
context.

This constructor supports a number of experimental microformat
interval patterns. e.g.

 <span class="rrule">
    The summer lectures are held held <span class="freq">yearly</span>,
    every <span class="interval">2</span>nd year (1999, 2001, etc),
    every <span class="byday">Sunday</span>
    in January <abbr class="bymonth" title="1" style="display:none"></abbr>
    at <span class="byhour">8</span>:<span class="byminute">30</span> and
    repeated at <span class="byhour">9</span>:30.
 </span>

=cut

sub parse
{
	my $class   = shift;
	my $string  = shift;
	my $elem    = shift || undef;
	my $context = shift || undef;
	
	my $self    = bless {}, $class;

	$self->{'_context'} = $context;
	$self->{'_id'}      = $context->make_bnode;

	my @freq_nodes = searchClass('freq', $elem);
	unless (@freq_nodes)
	{
		if (lc $elem->tagName eq 'abbr' and $elem->hasAttribute('title'))
			{ return $class->parse_string($elem->getAttribute('title'), $context); }
		else
			{ return $class->parse_string(''.stringify($elem, 'value'), $context); }
	}

	$self->{'freq'} = uc stringify($freq_nodes[0], 'value');
	
	foreach my $n ($elem->getElementsByTagName('*'))
	{
		if ($n->getAttribute('class') =~ /\b (until|count) \b/x)
		{
			my $p = $1;
			unless (defined $self->{'until'} || defined $self->{'count'})
			{
				$self->{$p} = ''.stringify($n, 'value');
				$self->{$p} = HTML::Microformats::Datatype::DateTime->parse($self->{$p}, $elem, $context)
					if $p eq 'until';
			}
		}
		
		elsif ($n->getAttribute('class') =~ /\b (bysecond | byminute | byhour |
			bymonthday | byyearday | byweekno | bymonth | bysetpos) \b/x)
		{
			my $p = $1;
			my $v = stringify($n, 'value');
			my @v = split ',', $v;
			push @{ $self->{$p} }, @v;
		}

		elsif ($n->getAttribute('class') =~ /\b (byday | wkst) \b/x)
		{
			my $p   = $1;
			my $txt = stringify($n, 'value');
			my @v = split ',', $txt;

			foreach my $v (@v)
			{
				if ($v =~ /^\s*(\-?[12345])?\s*(MO|TU|WE|TH|FR|SA|SU)/i)
					{ $v = uc($1.$2); }
				else
					{ $v = uc($txt); }
				
				push @{ $self->{$p} }, "$v";
			}
		}
		
		if ($n->getAttribute('class') =~ /\b interval \b/x)
		{
			my $v = stringify($n, 'value');
			$self->{'interval'} = $v;			
		}
	}
	
	return $self;
}

=item C<< $r = HTML::Microformats::Datatype::RecurringDateTime->parse_string($string, [$context]) >>

Essentially just an alias for C<< new >>.

=back

=cut

sub parse_string
{
	my $class   = shift;
	my $string  = shift;
	my $context = shift || undef;
	my $self    = bless {}, $class;

	$self->{'_context'} = $context;
	$self->{'_id'}      = $context->make_bnode;

	my @parts  = split /\;/, $string;
	foreach my $part (@parts)
	{
		my ($k,$v) = split /\=/, $part;
		
		if ($k =~ /^( byday | wkst | bysecond | byminute | byhour |
			bymonthday | byyearday | byweekno | bymonth | bysetpos )$/xi)
		{
			$self->{ lc $k } = [ split /\,/, $v ];
		}
		elsif ($k =~ /^( interval | until | count | freq )$/xi)
		{
			$self->{ lc $k } = uc $v;
		}
	}
	
	return $self;
}

=head2 Public Methods

=over 4

=item C<< $r->to_string >>

Returns an iCal-RRULE-style formatted string representing the recurrance.

=cut

sub to_string
{
	my $self = shift;
	my $rv   = '';
	
	foreach my $p (qw(freq until count bysecond byminute byhour
		bymonthday byyear byweekno bymonth bysetpos byday wkst interval))
	{
		if (ref $self->{$p} eq 'ARRAY')
		{
			$rv .= sprintf("%s=%s;", uc $p, (join ',', @{$self->{$p}}))
				if @{$self->{$p}};
		}
		elsif (defined $self->{$p})
		{
			$rv .= sprintf("%s=%s;", uc $p, $self->{$p});
		}
	}
	
	$rv =~ s/\;$//;
	
	return $rv;
}

=item C<< $r->datatype >>

Returns an the RDF datatype URI representing the data type of this literal.

=cut

sub datatype
{
	my $self = shift;
	return 'http://buzzword.org.uk/rdf/icaltzdx#recur';
}

=item C<< $r->add_to_model($model) >>

Adds the recurring datetime to an RDF model as a resource (not a literal).

=back

=cut

sub add_to_model
{
	my $self  = shift;
	my $model = shift;
	my $me    = RDF::Trine::Node::Blank->new( substr($self->{'_id'}, 2) );
	
	my $ical  = 'http://www.w3.org/2002/12/cal/icaltzd#';
	
	foreach my $p (qw(freq until count bysecond byminute byhour
		bymonthday byyear byweekno bymonth bysetpos byday wkst interval))
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$me,
			RDF::Trine::Node::Resource->new("${ical}${p}"),
			RDF::Trine::Node::Literal->new( (ref $self->{$p} eq 'ARRAY') ? (join ',', @{$self->{$p}}) : $self->{$p} ),
			))
			if defined $self->{$p};
	}
	
	$model->add_statement(RDF::Trine::Statement->new(
		$me,
		RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"),
		RDF::Trine::Node::Resource->new("http://buzzword.org.uk/rdf/icaltzdx#Recur"),
		));

	$model->add_statement(RDF::Trine::Statement->new(
		$me,
		RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#value"),
		RDF::Trine::Node::Literal->new($self->to_string, undef, $self->datatype),
		));

	return $self;
}

sub TO_JSON
{
	my $self = shift;
	return $self->to_string;
}

1;

__END__

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>,
L<HTML::Microformats::Datatype>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut
