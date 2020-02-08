# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Field::AuthResults;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Message::Field::Structured';

use warnings;
use strict;

use URI;



sub init($)
{   my ($self, $args) = @_;
    $self->{MMFA_server}  = delete $args->{server};
    $self->{MMFA_version} = delete $args->{version};

    $self->{MMFA_results} = [];
	$self->addResult($_) for @{delete $args->{results} || []};

    $self->SUPER::init($args);
}

sub parse($)
{   my ($self, $string) = @_;
	$string =~ s/\r?\n/ /g;

    (undef, $string) = $self->consumeComment($string);
    $self->{MMFA_server}  = $string =~ s/^\s*([.\w-]*\w)// ? $1 : 'unknown';

    (undef, $string) = $self->consumeComment($string);
    $self->{MMFA_version} = $string =~ s/^\s*([0-9]+)// ? $1 : 1;

    (undef, $string) = $self->consumeComment($string);
	$string =~ s/^.*?\;/;/;   # remove accidents

    my @results;
    while( $string =~ s/^\s*\;// )
    { 
        (undef, $string) = $self->consumeComment($string);
        if($string =~ s/^\s*none//)
        {   (undef, $string) = $self->consumeComment($string);
            next;
        }

		my %result;
		push @results, \%result;

        $string =~ s/^\s*([\w-]*\w)// or next;
	    $result{method} = $1;

        (undef, $string) = $self->consumeComment($string);
        if($string =~ s!^\s*/!!)
        {   (undef, $string) = $self->consumeComment($string);
            $result{method_version} = $1 if $string =~ s/^\s*([0-9]+)//;
        }

        (undef, $string) = $self->consumeComment($string);
        if($string =~ s/^\s*\=//)
        {   (undef, $string) = $self->consumeComment($string);
            $result{result} = $1
                if $string =~ s/^\s*(\w+)//;
        }

        (my $comment, $string) = $self->consumeComment($string);
        if($comment)
        {   $result{comment} = $comment;
            (undef, $string) = $self->consumeComment($string);
        }

        if($string =~ s/\s*reason//)
        {   (undef, $string) = $self->consumeComment($string);
            if($string =~ s/\s*\=//)
            {   (undef, $string) = $self->consumeComment($string);
                $result{reason} = $1
                    if $string =~ s/^\"([^"]*)\"//
                    || $string =~ s/^\'([^']*)\'//
                    || $string =~ s/^(\w+)//;
            }
        }

        while($string =~ /\S/)
        {   (undef, $string) = $self->consumeComment($string);
			last if $string =~ /^\s*\;/;

            my $ptype = $string =~ s/^\s*([\w-]+)// ? $1 : last;
            (undef, $string) = $self->consumeComment($string);

            my ($property, $value);
            if($string =~ s/^\s*\.//)
            {   (undef, $string) = $self->consumeComment($string);
                $property = $string =~ s/^\s*([\w-]+)// ? $1 : last;
                (undef, $string) = $self->consumeComment($string);
                if($string =~ s/^\s*\=//)
                {   (undef, $string) = $self->consumeComment($string);
                    $string =~ s/^\s+//;
                       $string =~ s/^\"([^"]*)\"//
                    || $string =~ s/^\'([^']*)\'//
                    || $string =~ s/^([\w@.-]+)//
                    or last;

                    $value = $1;
                }
            }

            if(defined $value)
            {   $result{"$ptype.$property"} = $value;
            }
            else
            {   $string =~ s/^.*?\;/;/g;   # recover from parser problem
            }
        }
    }
	$self->addResult($_) for @results;

	$self;
}

sub produceBody()
{   my $self = shift;
    my $source  = $self->server;
    my $version = $self->version;
    $source    .= " $version" if $version!=1;

	my @results;
    foreach my $r ($self->results)
    {   my $method = $r->{method};
		$method   .= "/$r->{method_version}"
            if $r->{method_version} != 1;

        my $result = "$method=$r->{result}";

        $result   .= ' ' . $self->createComment($r->{comment})
			if defined $r->{comment};

	    if(my $reason = $r->{reason})
        {   $reason =~ s/"/\\"/g;
		    $result .= qq{ reason="$reason"};
        }

        foreach my $prop (sort keys %$r)
        {   index($prop, '.') > -1 or next;
            my $value = $r->{$prop};
            $value    =~ s/"/\\"/g;
            $result  .= qq{ $prop="$value"};
        }

		push @results, $result;
    }

    push @results, 'none' unless @results;
    join '; ', $source, @results;
}

#------------------------------------------



sub addAttribute($;@)
{   my $self = shift;
    $self->log(ERROR => 'No attributes for Authentication-Results.');
    $self;
}



sub server()  { shift->{MMFA_server} }
sub version() { shift->{MMFA_version} }


sub results() { @{shift->{MMFA_results}} }


sub addResult($)
{   my $self = shift;

	my $r = @_==1 ? shift : {@_};
    $r->{method} && $r->{result} or return ();
    $r->{method_version} ||= 1;
    push @{$self->{MMFA_results}}, $r;
    delete $self->{MMFF_body};

    $r;
}

#------------------------------------------


1;
