package Language::BF;
use 5.008001;
use strict;
use warnings;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.3 $ =~ /(\d+)/g;

sub new($;$$) {
    my $class = shift;
    my $bf = bless {}, $class;
    $bf->code(shift)  if @_;
    $bf->input(shift) if @_;
    $bf;
}

sub new_from_file {
    my $bf    = shift->new();
    my $bfile = shift or die __PACKAGE__, "->new_from_file(filename)";
    open my $fh, "<", $bfile or die "$bfile:$!";
    my $src = do { local $/; <$fh> };
    close $fh;
    $bf->code($src);
    $bf;
}

sub reset($){
    my $bf = shift;
    ( $bf->{pc}, $bf->{sp} ) = ( 0, 0 );
    ( $bf->{data}, $bf->{in}, $bf->{out} ) = ( [], [], [] );
    $bf;
}

sub code($$) {
    my ( $bf, $code ) = @_;
    $code =~ tr/<>+\-.,[]//cd;
    $bf->{code} = [ split //, $code ];
    my $coderef = $bf->compile;
    warn $coderef unless ref $coderef;
    $bf->{coderef} = $bf->compile;
    $bf->reset;
    $bf;
}
*parse = \&code;

sub compile($){
    my $bf  = shift;
    my $src = <<'EOS';
sub { 
my (@data, @out) = ();
my $sp = 0;
EOS
    for my $op ( @{ $bf->{code} } ) {
        $src .= {
            '<' => '$sp--;',
            '>' => '$sp++;',
            '+' => '$data[$sp]++;',
            '-' => '$data[$sp]--;',
            '.' => 'push @out, $data[$sp];',
            ',' => '$data[$sp] = shift @_;',
            '[' => 'while($data[$sp]){',
            ']' => '}',
          }->{$op}
          . "\n";
    }
    $src .= <<'EOS';
return @out
}
EOS
    my $coderef = eval $src;
    return $@ ? $@ : $coderef;
}

sub run($;$){
    my ($bf, $interpret) = shift;
    if ($interpret){
	$bf->step while ( $bf->{code}[ $bf->{pc} ] and $bf->{pc} >= 0 );
    }else{
	$bf->{out} = [ $bf->{coderef}($bf->{in}) ];
    }
}

sub debug { my $bf = shift; $bf->{debug} = shift if @_;  $bf->{debug} };

sub input($$){
    my ($bf, $input) = @_;
    $bf->{in} =  [ split //, $input ];
    $bf;
}

sub output($){
    my $bf = shift;
    join '', map {chr} @{$bf->{out}};
}

sub as_source($) {
    my $bf = shift;
    require B::Deparse;
    B::Deparse->new()->coderef2text( $bf->{coderef} );
}

sub as_perl($) {
    'print map{chr} sub'. $_[0]->as_source
	. '->(split//, do{local $/;my $s=<>})' . "\n";
}

sub step($){
    my $bf = shift;
    my $op = $bf->{code}[ $bf->{pc} ];
    $bf->{debug}
      and warn sprintf "pc=%d, sp=%d, op=%s", $bf->{pc}, $bf->{sp}, $op;
    {
        '<' => sub { $bf->{sp} -= 1 },
        '>' => sub { $bf->{sp} += 1 },
        '+' => sub { $bf->{data}[ $bf->{sp} ]++ },
        '-' => sub { $bf->{data}[ $bf->{sp} ]-- },
        '.' => sub { push @{ $bf->{out} }, $bf->{data}[ $bf->{sp} ] },
        ',' => sub { $bf->{data}[ $bf->{sp} ] = shift @{ $bf->{in} } },
        '[' => sub {
            return if $bf->{data}[ $bf->{sp} ];
            my $nest = 1;
            while ($nest) {
                $bf->{pc} += 1;
                $nest     +=
                    $bf->{code}[ $bf->{pc} ] eq '[' ? +1
                  : $bf->{code}[ $bf->{pc} ] eq ']' ? -1
                  : 0;
		die "matching ] not found!"
		    if $bf->{pc} > scalar @{ $bf->{code} };
            }
        },
        ']' => sub {
            my $nest = 1;
            while ($nest) {
                $bf->{pc} -= 1;
                $nest     -=
                    $bf->{code}[ $bf->{pc} ] eq '[' ? +1
                  : $bf->{code}[ $bf->{pc} ] eq ']' ? -1
                  : 0;
		die "matching [ not found!"
		    if $bf->{pc} < 0;
            }
	    $bf->{pc}--;
        },
    }->{$op}();
    $bf->{pc}++;
}

sub as_c($;$){
    my $bf  = shift;
    my $datasize = shift || 65536;
    my $src = <<"EOS";
int main(int argc, char **argv){ 
char data[$datasize];
int  sp = 0;
EOS
    for my $op ( @{ $bf->{code} } ) {
        $src .= {
            '<' => 'sp--;',
            '>' => 'sp++;',
            '+' => 'data[sp]++;',
            '-' => 'data[sp]--;',
            '.' => 'putchar(data[sp]);',
            ',' => 'data[sp] = getchar();',
            '[' => 'while(data[sp]){',
            ']' => '}',
          }->{$op}
          . "\n";
    }
    $src .= <<'EOS';
}
EOS
    return $src;
}


1;
__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Language::BF - BF virtual machine in perl

=head1 SYNOPSIS

  my $bf = Language::BF->new(<<EOC);
  ++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<
  +++++++++++++++.>.+++.------.--------.>+.>.
  EOC
  $bf->run;
  print $bf->output; # "Hello World!\n";

=head1 DESCRIPTION

Language::BF is a straightforward (rather boring) implementation of 
Brainfuck programming language.

Language::BF is a OOP module that offers following methods

=head2 METHODS

=over 2

=item new([$code, $input])

Constructs the BF virtual machine.

=item new($filename)

Constructs the BF virtual machine from BF source file.

=item reset

Resets the virtual machine to its initial state

=item code($code)

=item parse($code)

$econstruct the virtual machine.  does. C<< $bf->reset >>

=item input

Sets the stdin of the virtual machine.

=item run([$mode])

Runs the virtual machine.  By default it runs perl-compiled code. 
By setting C<$mode> to non-zero value, it runs as an iterpreter.

=item step

Step-executes the virtual machine.

=item output

Retrieves the stdout of the virtual machine.

=item as_source

Returns the perl-compiled source code that implements the virtual machine.

=item as_perl

Returns the executable perl code; the difference between this and
C<as_source> is that this one adds interface to STDIN/STDOUT so it can
be directly fed back to perl.

  perl -MLanguage::BF \
       -e 'print Language::BF->new_from_file(shift)->as_perl' source.bf\
       | perl

is equivalent to running source.bf.

=item as_c

Returns the c source.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Acme::Brainfuck>

L<http://en.wikipedia.org/wiki/Brainfuck>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
