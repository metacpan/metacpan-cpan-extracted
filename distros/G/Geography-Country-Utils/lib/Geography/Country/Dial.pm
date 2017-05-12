#                              -*- Mode: Perl -*- 
################### Original code was by
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Mon Aug 28 16:37:39 1995
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Mar 24 14:21:39 1996
# Language        : Perl
# Update Count    : 5
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1995, Universität Dortmund, all rights reserved.
# 
# HISTORY
# 
# $Locker: pfeifer $
# $Log: Country.pm,v $
# Revision 0.1.1.1  1996/03/25 11:19:18  pfeifer
# patch1:
#
# Revision 1.1  1996/03/24 13:33:52  pfeifer
# Initial revision
#
# 
######### Changed database to dial codes

package Geography::Country::Dial;
BEGIN {
        eval { require Net::Country; };
}

require Exporter;
@EXPORT_OK = qw(dialcode);
@ISA = qw(Exporter);

$VERSION = 1.01;

while (<DATA>) {
    chop;
    ($cc, $rest) = split /\|/;
    next unless $cc;
    $country{lc($cc)} = $rest;
    }
close (DATA);

sub dialcode { $country{lc($_[0])} || $country{lc(Net::Country::Name($_[0]))};}

1;

__DATA__
Afghanistan|93
Albania|355
Algeria|213
American Samoa|684
Andorra|376
Angola|244
Anguilla|1
Antarctica|672
Antigua|1
Argentina|54
Armenia|374
Aruba|297
Ascension Island|247
Australia|61
Austria|43
Azerbaijan|994
Bahamas|1
Bahrain|973
Bangladesh|880
Barbados|1
Barbuda|1
Belarus|375
Belgium|32
Belize|501
Benin|229
Bermuda|1
Bhutan|975
Bolivia|591
Bosnia & Herzogovina|387
Botswana|267
Brazil|55
British Virgin Islands|1
Brunei|673
Bulgaria|359
Burkina Faso|226
Burundi|257
Cambodia|855
Cameroon|237
Canada|1
Cape Verde Islands|238
Cayman Islands|1
Central African Republic|236
Chad|235
Chatham Island|64
Chile|56
China (PRC)|86
Christmas Island|61
Cocos-Keeling Islands|61
Colombia|57
Comoros|269
Congo|242
Congo, Democratic Republic of|243
Cook Islands|682
Costa Rica|506
Croatia|385
Cuba|53
Curaçao|599
Cyprus|357
Czech Republic|420
Denmark|45
Diego Garcia|246
Djibouti|253
Dominica|1
Dominican Republic|1
East Timor|670
Easter Island|56
Ecuador|593
Egypt|20
El Salvador|503
Equatorial Guinea|240
Eritrea|291
Estonia|372
Ethiopia|251
Faeroe Islands|298
Falkland Islands|500
Fiji Islands|679
Finland|358
France|33
French Antilles|596
French Guiana|594
French Polynesia|689
Gabon|241
Gambia|220
Georgia|995
Germany|49
Ghana|233
Gibraltar|350
Global Mobile Satellite System (GMSS)|881
Greece|30
Greenland|299
Grenada|1
Guadeloupe|590
Guam|1
Guantanamo Bay|5399
Guatemala|502
Guinea-Bissau|245
Guinea (PRP)|224
Guyana|592
Haiti|509
Honduras|504
Hong Kong|852
Hungary|36
Iceland|354
India|91
Indonesia|62
Inmarsat (Atlantic Ocean - East)|871
Inmarsat (Atlantic Ocean - West)|874
Inmarsat (Indian Ocean)|873
Inmarsat (Pacific Ocean)|872
Inmarsat SNAC|870
Iran|98
Iraq|964
Ireland|353
Iridium|8816
Israel|972
Italy|39
Ivory Coast|225
Jamaica|1
Japan|81
Jordan|962
Kazakhstan|7
Kenya|254
Kiribati|686
Korea (North)|850
Korea (South)|82
Kuwait|965
Kyrgyz Republic|996
Laos|856
Latvia|371
Lebanon|961
Lesotho|266
Liberia|231
Libya|218
Liechtenstein|423
Lithuania|370
Luxembourg|352
Macau|853
Macedonia|389
Madagascar|261
Malawi|265
Malaysia|60
Maldives|960
Mali Republic|223
Malta|356
Marshall Islands|692
Martinique|596
Mauritania|222
Mauritius|230
Mayotte Island|269
Mexico|52
Micronesia|691
Midway Island|808
Moldova|373
Monaco|377
Mongolia|976
Montserrat|1
Morocco|212
Mozambique|258
Myanmar|95
Namibia|264
Nauru|674
Nepal|977
Netherlands|31
Netherlands Antilles|599
Nevis|1
New Caledonia|687
New Zealand|64
Nicaragua|505
Niger|227
Nigeria|234
Niue|683
Norfolk Island|672
Norway|47
Oman|968
Pakistan|92
Palau|680
Palestine|970
Panama|507
Papua New Guinea|675
Paraguay|595
Peru|51
Philippines|63
Poland|48
Portugal|351
Puerto Rico|1
Qatar|974
Réunion Island|262
Romania|40
Russia|7
Rwanda|250
St. Helena|290
St. Kitts/Nevis|1
St. Lucia|1
St. Pierre & Miquelon|508
St. Vincent & Grenadines|1
San Marino|378
São Tomé and Principe|239
Saudi Arabia|966
Senegal|221
Serbia|381
Seychelles Islands|248
Sierra Leone|232
Singapore|65
Slovak Republic|421
Slovenia|386
Solomon Islands|677
Somalia|252
South Africa|27
Spain|34
Sri Lanka|94
Sudan|249
Suriname|597
Swaziland|268
Sweden|46
Switzerland|41
Syria|963
Taiwan|886
Tajikistan|992
Tanzania|255
Thailand|66
Togo|228
Tokelau|690
Tonga Islands|676
Trinidad & Tobago|1
Tunisia|216
Turkey|90
Turkmenistan|993
Turks and Caicos Islands|1
Tuvalu|688
Uganda|256
Ukraine|380
United Arab Emirates|971
United Kingdom|44
United States of America|1
US Virgin Islands|1
Universal Personal Telecommunications (UPT)|878
Uruguay|598
Uzbekistan|998
Vanuatu|678
Vatican City|39
Venezuela|58
Vietnam|84
Wake Island|808
Wallis and Futuna Islands|681
Western Samoa|685
Yemen|967
Yugoslavia|381
Zambia|260
Zanzibar|255
Zimbabwe|263
