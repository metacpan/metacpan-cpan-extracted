package Doc::Simply::Extractor;

use strict;
use warnings;

# This is a dummy package containing Extractor::SlashStar & Extractor::SimplePound 
#
# The ->extract method returns an ARRAY (reference) yielding either:
#   
#       line => <content>
#       block => <content>

use Text::FixEOL;
our $fixer = Text::FixEOL->new;

package # Hide
    Doc::Simply::Extractor::SlashStar;

=head1 NAME

Doc::Simply::Extractor::SlashStar - Extract content from /* ...  */ and // ... style commentary

=head1 DESCRIPTION

Doc::Simply::Extractor::SlashStar uses L<String::Comments::Extract> to parse JavaScript, Java, C, C++ content and extract
only the comments

=cut

use Any::Moose;
use Doc::Simply::Carp;

use String::Comments::Extract;

sub extract {
    my $self = shift;
    my $source = shift;

    return unless $source;

    $source = $fixer->fix_eol($source);
    my $comments = String::Comments::Extract::SlashStar->extract($source);

    my @comments;
    while ($comments =~ m{/\*(.*?)\*/|//(.*?)$}msg) {
        next unless defined $1 || defined $2;
        push @comments, defined $1 ? [ block => $1 ] : [ line => $2 ];
    }     

    return \@comments;
}

package # Hide
    Doc::Simply::Extractor::SimplePound;

=head1 NAME

Doc::Simply::Extractor::SimplePound - Extract content from # ... style commentary

=cut

use Any::Moose;
use Doc::Simply::Carp;

# TODO Does not deal with multi-line strings, etc.

has _extractor => qw/is ro lazy_build 1/;
sub _build__extractor {
    my $self = shift;
    return Doc::Simply::Extract::Match->new(filter => sub { return unless s/^\s*#//; $_ });
}

sub extract {
    my $self = shift;
    return $self->_extractor->extract(@_);
}

package Doc::Simply::Extractor::Filter;

use Any::Moose;
use Doc::Simply::Carp;

has filter => qw/is ro required 1 isa CodeRef/;

sub extract {
    my $self = shift;
    my $source = shift;

    return unless $source;

    my (@source, @comments)
    ;
    if (ref $source eq "ARRAY") {
        @source = @$source;
    }
    elsif (ref $source eq "") {
        $source = $fixer->fix_eol($source);
        @source = split m/\n/, $source;
    }
    else {
        croak "Don't understand source $source";
    }

    my $filter = $self->filter;

    {
        local $_;
        for my $line (@source) {
            next unless $line;
            next unless defined ($line = $filter->($_));
            push @comments, [ line => $line ];
        }
    }

    return \@comments;
}

1;
