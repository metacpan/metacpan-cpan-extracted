package HTML::ERuby;
# $Id: ERuby.pm,v 1.5 2002/04/14 01:04:49 ikechin Exp $
use strict;
use vars qw($VERSION $ERUBY_TAG_RE);
use IO::File;
use Carp ();
use Inline::Ruby qw(rb_eval);
use Data::Dumper;

$ERUBY_TAG_RE = qr/(<%%|%%>|<%=|<%#|<%|%>|\n)/so;
$VERSION = '0.02';

sub new {
    my $class = shift;
    my $self = bless {
    }, $class;
    $self;
}

sub compile {
    my ($self, %args) = @_;
    my $data;
    if ($args{filename}) {
	$data = $self->_open_file($args{filename});
    }
    elsif ($args{scalarref}) {
	$data = ${$args{scalarref}};
    }
    elsif ($args{arrayref}) {
	$data = join('', @{$args{arrayref}});
    }
    else {
	Carp::croak("please specify ERuby document");
    }
    my $vars = '';
    if ($args{vars}) {
	$vars = $self->_convert_vars($args{vars});
    }
    my $src = $self->_parse(\$data);
    return rb_eval($vars. $src);
}

sub _open_file {
    my ($self, $filename) = @_;
    local $/ = undef;
    my $f = IO::File->new($filename, "r") or Carp::croak("can not open eruby file: $filename");
    my $data = $f->getline;
    $f->close;
    return $data;
}

sub _convert_vars {
    my ($self, $vars) = @_;
    my $code = '';
    local $Data::Dumper::Deepcopy = 1;
    while(my ($name, $value) = each %$vars) {
	if (my $type = ref($value)) {
	    Carp::croak(__PACKAGE__. " supports String, Hash and Array only")
		    if $type ne 'ARRAY' && $type ne 'HASH';
	}
	my $dumped = Dumper $value;
	$dumped =~ s/\$VAR1 =//; # strip Data::Dumper '$VAR1 =' string.
	$code .= "$name = $dumped\n";
    }
    return $code;
}

# copy from erb/compile.rb and Perlize :)
sub _parse {
    my($self, $scalarref) = @_;
    my $src = q/_erb_out = '';/;
    my @text = split($ERUBY_TAG_RE, $$scalarref);
    my @content = ();
    my @cmd = ("_erb_out = ''\n");
    my $stag = '';
    my $token = '';
    for my $token(@text) {
	if ($token eq '<%%') {
	    push @content, '<%';
	    next;
	}
	if ($token eq '%%>') {
	    push @content, '%>';
	    next;
	}
	unless ($stag) {
	    if ($token eq '<%' || $token eq '<%=' || $token eq '<%#') {
		$stag = $token;
		my $str = join('', @content);
		if ($str) {
		    push @cmd, qq/_erb_out.concat '$str';/;
		}
		@content = ();
	    }
	    elsif($token eq "\n") {
		push @content, "\n";
		my $str = join('', @content);
		push @cmd, qq/_erb_out.concat '$str';/ if $str;
		@content = ();
	    }
	    else {
		push @content, $token;
	    }
	}
	else {
	    if ($token eq '%>') {
		my $str = join('', @content);
		if ($stag eq '<%') {
		    push @cmd, $str, "\n";
		}
		elsif ($stag eq '<%=') {
		    push @cmd, qq/_erb_out.concat( ($str).to_s );/;
		}
		elsif ($stag eq '<%#') {
		    # comment out SKIP!
		}
		@content = ();
		$stag = undef;
	    }
	    else {
		push @content, $token;
	    }
	}
    }
    if (@content) {
	my $str = join('', @content);
	push @cmd, qq/_erb_out.concat '$str';/;
    }
    push @cmd, '_erb_out;';
    return join('', @cmd);
}

1;

__END__

=pod

=head1 NAME

HTML::ERuby - ERuby processor for Perl.

=head1 SYNOPSIS

  use HTML::ERuby;
  my $compiler = HTML::ERuby->new;
  my $result = $compiler->compile(filename => './foo.rhtml');
  print $result;

=head1 DESCRIPTION

HTML::ERuby is a ERuby processor written in Perl.

parse ERuby document by Perl and evaluate by Ruby.

=head1 METHODS

=over 4

=item $compiler = HTML::ERuby->new

constructs HTML::ERuby object.

=item $result = $compiler->compile(\%option)

compile ERuby document and return result.
you can specify ERuby document as filename, scalarref or arrayref.

  $result = $compiler->compile(filename => $filename);
  
  $result = $compiler->compile(scalarref => \$rhtml);
  
  $result = $compiler->compile(arrayref => \@rhtml);

you can use the Perl variables in the ERuby document.
supported types are String, Hash and Array only. NO Objects.
See the simple example.

Perl code

  my %vars = (
       '@var' => 'foo', # Ruby instance variable
       'ARRAY_REF' => [qw(a b c)], # Ruby constant
       'hash_ref' => {foo => 'bar', 'bar' => 'baz'} # Ruby local variable
  );

  my $compiler = HTML::ERuby->new;
  print $compiler->compile(filename => './foo.rhtml', vars => \%vars);

ERuby document

  instance variable <%= @var %>
  <% ARRAY_REF.each do |v| %>
  <%= v %>
  <% end %>
  foo: <%= hash_ref['foo'] %>
  bar: <%= hash_ref['baz'] %>

Result

  instance variable foo
  
  a
  
  b
  
  c
  
  foo: bar
  bar: baz
  

=back

=head1 CAVEATS

this module is experimental.

=head1 AUTHOR

Author E<lt>ikebe@edge.co.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Inline> L<Inline::Ruby>

http://www2a.biglobe.ne.jp/~seki/ruby/erb.html

http://www.modruby.net/

=cut
