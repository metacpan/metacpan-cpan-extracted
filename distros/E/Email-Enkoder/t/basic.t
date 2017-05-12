use strictures;

package basic_test;

use Test::InDistDir;
use Test::More;
use utf8;
use open ':encoding(UTF-8)';

use Email::Enkoder qw' enkode enkode_mail ';

run();
done_testing;
exit;

=head1 WARNING

Despite being single-quoted most of the strings in here need extra
back-slashes since \\ is interpolated to a single \ even in single-quoted
strings.

=cut

sub run {
    my $input = "meüep";

    my %enkoder_tests = enkoder_tests();
    is( scalar @{ Email::Enkoder->enkoders }, scalar keys %enkoder_tests, "all enkoders have tests" );

    test_encoder( $input, $_, $enkoder_tests{$_} ) for sort keys %enkoder_tests;

    ok( test_randomness( $input ), "generation of random enkoder combinations works" );

    is( Email::Enkoder::js_wrap_quote( "aaaaa\\123", 12 ),
        qq|aaaaa"+\n"\\123|, "js_wrap_quote doesn't split up character sequences" );

    test_mail_enkoding( $input );

    return;
}

sub test_mail_enkoding {
    my ( $input ) = @_;

    my $enkoders = [ { perl => sub { $_[0] }, js => "" } ];
    my $mail = enkode_mail( $input, { max_length => 1, enkoders => $enkoders } );

    is(
        $mail,
        q|
<script type="text/javascript">
/* <![CDATA[ */
function perl_enkoder(){var kode=
"kode=\"document.write(\\\\\"<a href=\\\\\\\\\\\\\"mailto:meüep\\\\\\\\\\\\\">meüep</a>\\\"+
"\");\""
;var i,c,x;while(eval(kode));}perl_enkoder();
/* ]]> */
</script>
|,
        "email link generation works, as well as modification of enkoders list"
    );

    my $mail2 = enkode_mail(
        $input,
        {
            max_length      => 1,
            enkoders        => $enkoders,
            link_text       => qq|"$input"|,
            link_attributes => qq|title="$input" class="$input"|,
            subject         => $input
        }
    );

    is(
        $mail2,
        q|
<script type="text/javascript">
/* <![CDATA[ */
function perl_enkoder(){var kode=
"kode=\"document.write(\\\\\\"<a href=\\\\\\\\\\\\\\"mailto:meüep?subject=meüep\\\\\\\\\\\\"+
"\" title=\\\\\\\\\\\\\\"meüep\\\\\\\\\\\\\\" class=\\\\\\\\\\\\\\"meüep\\\\\\\\\\\\\\">\\\\\\\\\\\\\\"meüep\\\\"+
"\\\\\\\\\\"</a>\\\\\\");\""
;var i,c,x;while(eval(kode));}perl_enkoder();
/* ]]> */
</script>
|,
        "subject, link attribute and link text options work as well"
    );

    return;
}

sub test_encoder {
    my ( $input, $enkoder, $expected ) = @_;

    my $output = enkode( $input, { max_length => 1, enkoder_index => $enkoder } );
    is( $output, $expected, "enkoder $enkoder generates the expected output" );

    return;
}

sub test_randomness {
    my ( $input ) = @_;

    my $output = enkode( $input );
    cmp_ok( length $output, '>', 1024, "without limits the output is at least 1024 characters" );

    for ( 1 .. 1000 ) {
        my $output2 = enkode( $input );
        return 1 if $output ne $output2;
    }

    return;
}

sub enkoder_tests {
    (
        0 => q|
<script type="text/javascript">
/* <![CDATA[ */
function perl_enkoder(){var kode=
"kode=\";)\\\\\\"peüem\\\\\\"(etirw.tnemucod\";kode=kode.split('').reverse().join"+
"('')"
;var i,c,x;while(eval(kode));}perl_enkoder();
/* ]]> */
</script>
|,
        1 => q|
<script type="text/javascript">
/* <![CDATA[ */
function perl_enkoder(){var kode=
"kode=\"oducemtnw.iret\\\\\\"(emeü\\\\\\"p;)\";x='';for(i=0;i<(kode.length-1);i+="+
"2){x+=kode.charAt(i+1)+kode.charAt(i)}kode=x+(i<kode.length?kode.charAt(ko"+
"de.length-1):'');"
;var i,c,x;while(eval(kode));}perl_enkoder();
/* ]]> */
</script>
|,
        2 => q|
<script type="text/javascript">
/* <![CDATA[ */
function perl_enkoder(){var kode=
"kode=\"grfxphqw1zulwh+%phÿhs%,>\";x='';for(i=0;i<kode.length;i++){c=kode.c"+
"harCodeAt(i)-3;x+=String.fromCharCode(c)}kode=x"
;var i,c,x;while(eval(kode));}perl_enkoder();
/* ]]> */
</script>
|,
    );
}
