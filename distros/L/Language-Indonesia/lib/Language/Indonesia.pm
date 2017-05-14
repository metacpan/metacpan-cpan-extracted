package Indonesia;
use Filter::Simple;
use strict;


our $VERSION = '0.0.2';

FILTER{

my %scalar_string = (
'panjang' => 'length',
'potong' => 'chop',
'potongkan' => 'chomp',
'karakter' => 'chr',
'sandi' => 'crypt',
'huruf kecil' => 'lc',
'huruf besar' => 'uc',
'ordinal' => 'ord',
'pak' => 'pack',
'balikan' => 'reverse',
'sub string' => 'substr',
'cetak' => 'print',
'format_cetakan' => 'printf'
);

my %function = (
'absolut' => 'abs',
'tangen' => 'atan2',
'kosinus' => 'cos',
'pangkat' => 'exp',
'heksadesimal' => 'hex',
'integer' => 'int',
'logaritma' => 'log',
'oktal' => 'oct',
'acak' => 'rand',
'sinus' => 'sin',
'akar' => 'sqrt',
'acak_seed' => 'srand'
);

my %func_array = (
'ambil' => 'pop',
'tambah' => 'push',
'pindah' => 'shift',
'sambung' => 'splice'
# '' => 'unshift'
);

my %list_data = (
# '' => 'grep',
'gabung' => 'join',
# '' => 'map',
# '' => 'qw/STRING/',
'urut' => 'sort',
# '' => 'unpack'
);

my %func_hash = (
'hapus' => 'delete',
'setiap' => 'each',
'ada' => 'exists',
'kunci' => 'keys',
'nilai' => 'values'
);

my %scope = (
'panggil' => 'caller',
# '' => 'import',
# 'lokal' => 'local',
'lokal' => 'my',
# '' => 'our',
'paket' => 'package',
'gunakan' => 'use'
);

my %module = (
'tidak' => 'no', # 'tidak' means 'no', but it will confuse others, especially Indonesian
'perlu' => 'require',
);

my $i;

foreach $i(keys %scalar_string){
	s/\b$i\s*(.*?);/$scalar_string{$i} $1;/g;
}

foreach $i(keys %function){
	s/\b$i\s*(.*?);/$function{$i} $1;/g;
}

foreach $i(keys %func_array){
	s/\b$i\s*(.*?);/$func_array{$i} $1;/g;
}




s/\bjika\s*?\(((.|\n)*?)\)\s*?\{((.|\n)*?)\}/if($1){$3}/g;
s/\bketika\s*?\((.*?)\)\s*?\{((.|\n)*?)\}/while($1){$2}/g;
s/\blakukan((.|\n)*?)\}/do $1}/g;
s/\blakukan\s*(.*?);/do $1;/g;
s/\buntuk\s*?\(.*?\)\s*?\{(.*?)\}//g;

};

1;



=head1 NAME

Language::Indonesia - Write Perl program in Bahasa Indonesia.

=head1 SYNOPSIS

    use Language::Indonesia;

=head1 DESCRIPTION

This module will help a lot of Indonesian programmers (most of them
aren't good enough in english) to write Perl program in Bahasa Indonesia.

The linguistic principles behind Language::Indonesia are described in:

    http://www.anti-php.net/~daniels/index.pl?_work=indonesia

=begin html

<pre>
Conversion table:
<br />
    Bahasa Indonesia      perlfunc
    =========             =======
    cetak                 print
    format_cetakan        printf
    potongkan             chomp
    potong                chop
    untuk                 for
    selagi                while
    lakukan               do
etc.

</pre>

There's a lot of ambiguity in this module, for example:

<pre>
tidak strict;    # no strict;  ?
</pre>

Will confuse Indonesian programmers, I think. :-)

=end html

=head1 BUGS

Not all Perl built-in function implemented.

=head1 AUTHOR

Daniel Sirait E<lt>dns@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Daniel Sirait

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut


