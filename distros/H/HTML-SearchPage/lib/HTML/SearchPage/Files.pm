package HTML::SearchPage::Files;

our $VERSION = '0.05';

# $Id: Files.pm,v 1.7 2007/09/19 21:30:18 canaran Exp $

use warnings;
use strict;

use Carp;
use Storable;

sub new {
    my ($class, %params) = @_;

    my $self = bless {}, $class;

    eval {
        exists $params{temp_dir} or croak("A temp_dir param is required!");
        $self->temp_dir($params{temp_dir});
    };

    $self->croak($@) if $@;

    $self->create_files;

    return $self;
}

sub create_files {
    my ($self) = @_;

    my $files_ref = $self->files;
    my $temp_dir  = $self->temp_dir;

    foreach my $file_name (keys %$files_ref) {
        my $file_content = $files_ref->{$file_name}->{content};
        my $file_type    = $files_ref->{$file_name}->{type};
        
        if ($file_type eq 'binary') {
            $file_content =~ s/\n//g;
            
            my $binary_content = pack('H*', $file_content);
            
            open(OUT, ">$temp_dir/$file_name")
              or croak("Cannot write file ($temp_dir/$file_name): $!");
            binmode OUT;
            
            print OUT $binary_content;

            close OUT;
        }    
        
        else {
            open(OUT, ">$temp_dir/$file_name")
              or croak("Cannot write file ($temp_dir/$file_name): $!");

            $file_content =~ s/^\s+//;
            $file_content =~ s/\s+$/\n/;

            print OUT $file_content;

            close OUT;
        }    


    }

    return 1;
}

sub temp_dir {
    my ($self, $value) = @_;

    $self->{temp_dir} = $value if @_ > 1;

    return $self->{temp_dir};
}

sub files {
    my ($self) = @_;

    my %files;

    
    $files{'left-arrow.png'}{'type'}    = 'binary';
    $files{'left-arrow.png'}{'content'} = <<'CONTENT';
89504e470d0a1a0a0000000d49484452000000580000002a0802000000b8
1d0ba9000000097048597300000b1300000b1301009a9c18000000077449
4d4507d5081211382e92ea8b9a000003024944415468dee59acb4ee33014
867dab934a6d15322c46202a315ca42c58b38137288fce860d6251814469
341a6833b948891bdb2cdc494bb9081aa7e3102b8b366a7bfc7f3df6f9ed
180a2180a94d4a59bc1042e6b9144222045b2d841084106a8c456aa13fcf
451832df4fe278d6ebd17ebfeb38164240230b62befef1389e4eb3d128be
bafaf3f4941e1f6f0d06fb9d0ea5f47b65c467f48f46f1749af97e329bf1
3c9767673b9c4bbddd20e6eb1f8fe33064792ef25c5a16668c732e01a839
88f5f40b31ff9e9440ca4a3a466aa15f21d05a25360ba2bc7e8560038d18
ab7fb9a95c80707e4909a494522b2162b2fe650a4510ce05633c4d39007a
7c847268c458fd0585e58f712e8320bbbe9e00002845e54120041dc7eaf7
bb706d8b5db5fe97b1e63755bff7f63a8e639571d9c5d44b29f63cf7e262
9f98acfff57d2164106471cc10826b8f8ca2271082769b0000cecf7788c9
fadf6c4248c664b9b1fc22ae7268a42efa3596d295daacde925ae8dfb48f
68a0fe17206aa45ffbafa90b00409443134234eaff7f232384908c892048
c7e36432499ba67f01220cd9fd7d747333bdbcfc7d77173e3ea68dd2bf00
1145ecf6361c0e8387876438fc3b99a469cab38c3707c11c44af478f8e9c
ad2d6b77b7b3bd6d7f7550ac98931a83e876e9c141abdfef1e1e3a9ee7ae
3d4dd69d084108520a5b2d68dbd8756d55384e4e7e348d0829162e18438c
01a5483b118d502ab7d8cbeb38ed446a9126e45515682811f27e5d349148
8516fb139f5e87481431ce174f6e354eae084142a0c68d194a31c6907c85
df1788f87e9265228a98967253f5569de358b0ccb180f797ad4914655926
7c3f29bf7259064429f23c7730f8e579aedecd5b526e8cbd9b234248ce65
14692bc04514c7b13ccf3d3dfd69dbd8acedfc3789a83469b7b54dae4528
8c11a5d8b671bb4dcc3d1fb1d2332de5e6b5ff8110c07fcd50105514e095
673c9bf6114611f99f86ca4c2285ffa93788d2266d665958f91f00e07700
b1b649430829ff83b16610d0b473961f9a34060050fea7a4b3ac01880f88
a859b3a203a7cfabf2096d37b2e1460000000049454e44ae426082
CONTENT
    
    $files{'right-arrow.png'}{'type'}    = 'binary';
    $files{'right-arrow.png'}{'content'} = <<'CONTENT';
89504e470d0a1a0a0000000d49484452000000580000002a0802000000b8
1d0ba9000000097048597300000b1300000b1301009a9c18000000077449
4d4507d5081211381fc3348ba0000002fc4944415468dee59ac14ee33010
86c7f624294a13a5a5bbab464570435c38c0a3036fc009212e4844e2b048
542b2121ba0116b509b1670f46d9d25d582076eb0a2b874aadc6335fc7e3
df1333a514981b44a4143d3e2aa5887386c838678c31fd6dfdc1c181c629
e4797179797f7757b6db5ebf1fc6b18fc83591fa970e1241b3e6aa8a86c3
fb83838bf3f39fababadeded2f8341bbd309d2b4ed3811c320a4a43c2fce
ce46c7c7579e274e4f6f3a9d603068bb4f044d1b2429a92ce5c3435514c5
cdcd1891c7b1ef3e11b461940888404a0d454d2672349a384e04ad5a277a
5a2fee1341db1368168cb99e2348da5343db27111101634fcf348b69340e
12c15aff18013199c8b294522a009af2fbc5647187086afd93e745731644
54962acb46795e48f9cc9a5e1aaf2c9f8513612727577b7b1759362a4ba9
7dfab0cd5a590e87bf34d9ba40fc5d35fee31603add03591346dbf4ea4b9
8ac73c2fb26c747474351e57b58b1fb3460400a4145515e9fcfaa79d976a
c7627304b5fe198fabe620de9d8d2e11c15affe8c7469c4b4104c1a5b140
226e81582011d4b34eeb9fb9d508a788389a11f325c201686940d820d2ed
b6d2344c9296eff3e503618a48afd7dad8887777bf6d6e76d6d6a2250631
43e4f5bd5f13d1628fa82c8adbdbdbc2f34492e4be2f9224587a104d04fb
ceced7f5f5b8d75b89631f3f61fc3325d3f30422c34f1bffcc81cd0989dd
3cf8e607565cea3fdfe0811d3f79fcce49ec45c5ff078410ccf7c5ca0a4e
7b63aa3163b6f871ce84605164a5618549126c6d7501606eadba0f17ff28
f28380f7fba18d861dbbbe7e30debcdddfff9e65a3b2543329d670f3ebf7
c320e05114a46968b661f9941161e8196ce703c0e1e10f21d8bb52e02d8b
3f8a7c2198a56b17c8390b0261a8e01100f8be10820330abc50f4cbfe641
b3e61863fa15c68c429b9964feddfa37356fe7765e7630fe3981d0febb1c
bf5d10b542733f7e7b2058add0386751e4391ebf2d1042b05aa129a52c89
1f2b596cf09ee5f4f5c23c2f00208a7c1be2c77510f0fcc229002cd19dd3
df6fa810729fc5bc3a0000000049454e44ae426082
CONTENT
    
    $files{'sort-button.png'}{'type'}    = 'binary';
    $files{'sort-button.png'}{'content'} = <<'CONTENT';
89504e470d0a1a0a0000000d49484452000000280000002808060000008c
feb86d000000097048597300000b1300000b1301009a9c18000000077449
4d4507d506030f2a2bdb590f270000074a4944415458c3cd985b6f1ad71a
861f603833c3c106823383b1bd953a2671a2b417e6be77bdceffd9ff2777
fd075b550bad92a8556576e3edd8861930f660603084b3d917308483ed80
d5bd95258d8498c37ad6bbbef59d2c0707f230959249a514bea6914eaba4
d31a82a248a4520aaf5f27f9da86a6d5111ef2a2aa1a685a1d4dab2ff5bc
2c4bc8b284a2f8579e4b780894aad6d1346345403f8a22ad0c2b2c0b97c9
68a4d3ead250f35ba56975329911ac69efcb400acba8964e6b64322aaa3a
824ba5e48922cb2d70a4783aad8d7f8f7661f49dfbd5145651cd045be6c3
b72d5496fd13d3c8645434cdf8a29ac27d706fde1ca2aa751445e2e04059
19cc1c8ae24751fcc8b234b323e9b4366332b77d575806eef5eb24070732
8ae2673894180e455a2d07b55a8d7259a75aadd16c36e9763bf4fb036088
cd66c36eb7e3743af1783cf87c22c1e063924985586c0345912673bc7973
7827a4b00a1c40ab25502c76393e36f8f8f123a552e91640b0d9ac6340d7
18d0c7f6f636cf9e05f8e69b20070732c0172185f9d3964eab772ad76858
383ab2f2db6f05debe2d4d0156c7805dfafdfe18705e411fdf7de7c66eb7
2f988909994eab0bf78469f5d2698d745a03e0e04099516e30f090cb35f8
f9e7023ffef82ffefc3347a552c1ed76b3b6b6462291c0ebf562b7db01e8
f7fb743a1d9acd268661a0eb3aa7a7a7148b02ed7660462955ada3aa87a4
d31ab23cb2d505c091af3226a7359592675652af43367bcd4f3f9df1eedd
7fa8d56a84c36176773778f9729b783c30061400cb02e0d5558ff5f56db6
b7a3b85c2ea03d814ca5e4891b9a0f00c2e715d427eacdaf02a052a97072
72c2c9c909b55a0d80c78f1f934a3de5871f5eb2b969c5ebf58d01a1df1f
d0e9b4a700fb58ad01a251375eefe0d64803da44c5194053b9bbd403308c
3a8651c3303e3f1b8d4679f224c6cb976b48920634ef70341e06032f8381
1700abb5b1e086e6559c03ac4fad66513d80e1f0869b9b2137373753d006
a5d2274a2501bb7d0d97ab8bc5727d2ba2cdd6c4666b7e315e83b6b8c59f
57228daf4587e9f3f926d767bbd5c8641c0882c0de9e442211241673e1f7
5bb0db5b0f70e6d242f85c3a9b09854627359168727676c6f5f535a55289
b76ffbe87a87c3c347241221e2712b8ae2271ef7138d46114510844f582c
ab27192b01fafd7e924989f3f320d56a956c364bb55aa5542aa1eb3a4747
12d16894783c30018cc7afd9da5a637333442422e076f7ee3481bb862d99
0cff73fa8f6432423219b9c5863c783c1ebcde10a228e27088582c16badd
2e9d4e8756ab45b95c269fbfe0f4f48a7cbe4da1d0a5586c7279d9a6dd06
4108e176bbb1d9042c96cec21cd9ac4e36ab3f0c10c0e58260d04d24e224
1c8e100eaf130a6de0f58e4e67afd79bc05e5e5e92cfe7c9e54a148b0dca
e50e9d8e13876388cf67c7e1682f05b8f4168f6ca88ed77bcd93275e1e3d
7ac4eeae97e3e3754e4f3de4721ba86a8d7cdea0502850ad5669b7db148b
45745de7ecec8c5cae46b3b90f84d9dd75e27476fe3e1b9c06b5d9ea0402
4d020191adad0daeae9c63675f239f1f92cfd7c8e5aa1c1f1f532c16a9d7
eb148b455aad160e479b40608f7078838d0dfe7ec04545c1eb1df9b1fdfd
20baee42550d72b93ebfff1ee5d75fff4d369ba556ab8d0f9746362b914c
fad9d870ad0668863c5535564e4aadd606a2083edf90cdcd20cf9fcbecec
ec001286614cc2a3aeeb94cb65ca651d5066523d73fe695f689d2e0bcdb0
f790c268d604ce09069becedc9eceeee128bc526f7bbddeef8eadd525819
ccf30866781b3f3693f24cabf8e99340a7e364381471bb3db85c1de0fa1e
073ca4dbedd1ed76e9f57a539ec035be9cdc95ea993c93c2ddac57e7539e
69c0abab1ec7c70d34ed0aa7d3c9faba8360d08a288e1252a7d381d56ae5
e6e68656ab4da552e5afbf54debf3fa450284cbe1389448844c284c311ee
4bf5cc3255b82fe59956f1eaaac71f7f5c91c9d4190c0663401ba2389c02
b47173331803f6393a2a7178a8727e7e3e0e9721f6f6649e3e9589c53c40
ef56f5cce26ae690cca73c998c3a315645f1d36ab5c8e7f3fcf24b165dd7
f1f97c04020144511c033aa7146c51a9542897cbd4eb75ac562b8aa2b0bf
bfcff7df3f637f3f4c30d84755cb6432a3b9e653bd4c465b3cc566d56f16
d6d3858c244924129b3c7f6ee3f4f49446a341a552a15028d0ebf5180c06
33b588dbed461445e2f138b1588c9d9d30af5efd8357af9c6c6dd9b9b828
2c1468a994b290ea09f329cf7c21634226125bbc78b18620d8b9b8f0d068
3468369bb45a2d7abdee18d032aee61c63401fa1d0da18709d44628d48a4
c3e5e5e517abc73b1df55d90df7edb637f3fc18b176bf8fd6b341acd5b00
17150c8542844221447148a9a4f2febd36d34ab90feece4832fda0d9fa78
f7ee888b8bd25cebe3d1129eb18baa7ee0c387fa425164364eef82bb37d4
992fc8b234d3aa18a5e4c6839b47a65b5bb695222cdb53511469a2e6743b
6db5b45e9a1cc4fb545b39599856f3ab6c604eabf97f6f019b3d91ff7533
7c6412da4a5d7e55ad6391656968dad8d734cc4eec7f012d979baddce1c4
d20000000049454e44ae426082
CONTENT
    
    $files{'searchpage-main.css'}{'type'}    = 'ascii';
    $files{'searchpage-main.css'}{'content'} = <<'CONTENT';
/*  Author: Payan Canaran <pcanaran@cpan.org> */
/*  $Id: Files.pm,v 1.7 2007/09/19 21:30:18 canaran Exp $ */
/*  Copyright 2005-2007 Cold Spring Harbor Laboratory */

/* aqua, black, blue, fuchsia, gray, green, lime, maroon, navy, olive, purple, red, silver, teal, yellow, white */
/* background-color: #ffffff */

body
{
font-family: helvetica, arial, 'sans serif'; 
font-size: 13;
color: #000000;
background-color: white;
}

form
{
font-family: helvetica, arial, 'sans serif'; 
font-size: 13;
color: #000000;
}

table
{
font-family: helvetica, arial, 'sans serif'; 
font-size: 13;
color: #000000;
}

td
{
padding: 2 2 2 2;
}

h1, h2, h3
{
color: #00008B;
}

h1
{
text-align: center;
font-weight: bold;
font-size: 32; 
}

h2
{
font-weight: bold;
font-size: 16; 
}

h3
{
font-weight: bold;
font-size: 12; 
}

.box
{
font-size: 13;
border-style: solid;
border-width: thin;
border-color: #616161;
background-color: #FFFF66;
}

.small_box
{
font-size: 11;
border-style: solid;
border-width: thin;
border-color: #616161;
background-color: #FFFF66;
}

.small_box2
{
font-size: 11;
border-style: solid;
border-width: thin;
border-color: #616161;
background-color: #EEE9E9;
}

.highlight
{
color: #FF0000;
font-style: italic;
}

.attention
{
font-size: 40;
color: #FF0000;
font-style: bold;
}

.fixed_width
{
font-family: courier; 
font-size: 13;
}

a:link    {color: #0000FF}
a:visited {color: #0000FF}
a:active  {color: #0000FF}
a:hover   {color: #660000}

.row_color_one
{
background-color: #FFFFCC;
}

.row_color_two
{
background-color: #EEEEEE;
}

.navigator_color
{
background-color: white;
}

.header_color
{
background-color: #EEEEEE;
}

CONTENT
    

    return \%files;
}

1;

__END__

=head1 NAME

HTML::SearchPage::Files - File storage for HTML::SearchPage

=head1 SYNOPSIS

  HTML::SearchPage::Files->new(temp_dir => '/tmp');

=head1 DESCRIPTION

This file is used by HTML::SearchPage as a storage for 
image files used in HTML pages.

=head1 USAGE

This file is not intended to be used directly. Please refer to
HTML::SearchPage::Tutorial for detailed usage information.

=head1 AUTHOR

Payan Canaran <pcanaran@cpan.org>

=head1 BUGS

=head1 VERSION

Version 0.05

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright (c) 2005-2007 Cold Spring Harbor Laboratory

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See DISCLAIMER.txt for
disclaimers of warranty.

=cut
