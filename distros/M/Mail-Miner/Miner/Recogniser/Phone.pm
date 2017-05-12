#!/usr/bin/perl -w

package Mail::Miner::Recogniser::Phone;
$Mail::Miner::recognisers{"".__PACKAGE__} = 
    {
     title => "Phone numbers",
     help  => "Match messages which contain a phone number",
     keyword => "phone"
    };

my $exchanges =
qr/(?:2(?:0[123456789]|1[023456789]|2[4589]|3[149]|4[0268]|5[012346]|6[024789]|7[06]|8[149])|3(?:0[123456789]|1[023456789]|2[013]|3[04679]|4[057]|5[12]|6[01]|86)|4(?:0[123456789]|1[023456789]|2[35]|3[45]|4[013]|50|69|7[0389]|8[04])|5(?:0[123456789]|1[023456789]|20|30|4[01]|5[19]|6[1237]|7[0134]|8[056])|6(?:0[123456789]|1[023456789]|2[036]|3[016]|4[1679]|5[01]|6[0124]|7[018]|82)|7(?:0[123456789]|1[23456789]|2[047]|3[124]|40|5[478]|6[0357]|7[023458]|8[014567])|8(?:0[0123456789]|1[023456789]|28|3[012]|4[3578]|5[06789]|6[023456789]|7[0678]|88)|9(?:0[123456789]|1[023456789]|2[058]|3[1679]|4[0179]|5[246]|7[012389]|8[059]))/ox;

sub process {
    my ($class, %hash) = @_;
    my $body = $hash{getbody}->();
    my $usphone_prefix = qr/\($exchanges\)|$exchanges/;
    my $usphone_suffix = qr/\s+\d{3}[-\s]+\d{4}/;

    my $usphone = qr/$usphone_prefix$usphone_suffix/;
    my $extension_suffix = qr/\s*(?:(?:ext|x)[\s.:]+\d+)?/i;

    $body =~ s/IS[SB]N\D+\d+x?//i; # Bastards.

    my %found = ();

    my $phonestuff = qr/\+?[\d\s\(\)-]+\d$extension_suffix/;

    # "Maximal munch"

    my $phone_words = qr/(?:t|p|Tel|phone|mobile|mob|f|fax|m|telephone)/i;
    $found{$1} = "sure" while $body =~ s/\b$phone_words[:.]*
                                \s*($phonestuff)//x;

    # Magic words
    my $magic = qr/number|phone|call|cell|mobile|fax|contact|ring/i;
    $found{$1} = "very likely" while $body =~ s/\b$magic[^+\(\d\)]+($phonestuff)//;

    # Oftel recommended presentations with brackets
    my $oftel_b = qr/
                 (\(0\d{3}\) \s+ \d{3} \s+ \d{4}|
                 \(0\d{2}\) \s+ \d{4} \s+ \d{4}|
                 \(0\d{4}\) \s+ \d{3} \s+ \d{3})/x;
    $found{$1} = "sure" while $body =~ s/(?:\b|^)($oftel_b$extension_suffix)(\b|$)//;

    # Oftel recommended presentations:
    my $oftel = qr/(01\d{2} \s+ \d{3} \s+ \d{4}|
                    01\d{3} \s+ \d{3} \s+ \d{3}|
                    02\d    \s+ \d{4} \s+ \d{4}|
                    0\d{4}  \s+ \d{3} \s+ \d{3})/x;
    $found{$1} = "UK" while $body =~ s/(?:\b|^)($oftel$extension_suffix)(\b|$)//;   

    # Lax Oftel:
    my $oftel_l = qr/(01\d{2} \s* \d{7}|
                      01\d{3} \s* \d{6}|
                      02\d    \s* \d{8}|
                 \(0\d{3}\) \s* \d{3} \s+ \d{4}|
                 \(0\d{2}\) \s* \d{4} \s+ \d{4}|
                 \(0\d{4}\) \s* \d{3} \s+ \d{3})/x;
    $found{$1} = "UK" while $body =~ s/(?:\b|^)($oftel_l$extension_suffix)(\b|$)//; 

    my $ukphone_int = qr/(\+44\s*|44\s+)\(?[\(\)\d]{2,8}\)?/;
    my $ukphone_code = qr/\(0\d{2,6}\)|0\d{2,6}\s+/;
    my $ukphone_suffix = qr/\s*[\d -]{6,15}/;
    my $ukphone = qr/($ukphone_int|$ukphone_code)$ukphone_suffix/;
    $found{$1} = "UK" while $body =~ s/(?:\b|^)($ukphone$extension_suffix)(\b|$)//;
    $found{$1} = "US" while $body =~ /(?:\b|^)($usphone)(\b|$)/g;


    return map { s/^\s+//; s/\s+$//; $_ } grep $_, keys %found;

}

1;
