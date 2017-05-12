package Encode::Detect::Upload::Data;

our $VERSION=0.04;

=head1 NAME

Encode::Detect::Upload::Data - structures mapping countries -> languages -> charsets

=head1 SYNOPSIS

    use Data::Dumper;
    use Encode::Detect::Upload::Data;
    print Dumper( \%Encode::Detect::Upload::Data::country_lang );
    print Dumper( \%Encode::Detect::Upload::Data::lang_charset );

=head1 DESCRIPTION

Made for use with Encode::Detect::Upload, but could be used standalone if you
just wanted access to the raw data.

=cut


use strict;
use warnings;
use vars qw( %country_lang %lang_charset );

%country_lang = (
    'ad' => {
        'languages' => [ 'ca' ],
        'name'      => 'Andorra'
    },
    'ae' => {
        'languages' => [ 'ar-ae', 'fa', 'en', 'hi', 'ur' ],
        'name'      => 'United Arab Emirates'
    },
    'af' => {
        'languages' => [ 'fa-af', 'ps', 'uz-af', 'tk' ],
        'name'      => 'Afghanistan'
    },
    'ag' => {
        'languages' => [ 'en-ag' ],
        'name'      => 'Antigua and Barbuda'
    },
    'ai' => {
        'languages' => [ 'en-ai' ],
        'name'      => 'Anguilla'
    },
    'al' => {
        'languages' => [ 'sq', 'el' ],
        'name'      => 'Albania'
    },
    'am' => {
        'languages' => [ 'hy' ],
        'name'      => 'Armenia'
    },
    'an' => {
        'languages' => [ 'nl-an', 'en', 'es' ],
        'name'      => 'Netherlands Antilles'
    },
    'ao' => {
        'languages' => [ 'pt-ao' ],
        'name'      => 'Angola'
    },
    'aq' => {
        'languages' => [],
        'name'      => 'Antarctica'
    },
    'ar' => {
        'languages' => [ 'es-ar', 'en', 'it', 'de', 'fr', 'gn' ],
        'name'      => 'Argentina'
    },
    'as' => {
        'languages' => [ 'en-as', 'sm', 'to' ],
        'name'      => 'American Samoa'
    },
    'at' => {
        'languages' => [ 'de-at', 'hr', 'hu', 'sl' ],
        'name'      => 'Austria'
    },
    'au' => {
        'languages' => [ 'en-au' ],
        'name'      => 'Australia'
    },
    'aw' => {
        'languages' => [ 'nl-aw', 'es', 'en' ],
        'name'      => 'Aruba'
    },
    'ax' => {
        'languages' => [ 'sv-ax' ],
        'name'      => 'Aland Islands'
    },
    'az' => {
        'languages' => [ 'az', 'ru', 'hy' ],
        'name'      => 'Azerbaijan'
    },
    'ba' => {
        'languages' => [ 'bs', 'hr-ba', 'sr-ba' ],
        'name'      => 'Bosnia and Herzegovina'
    },
    'bb' => {
        'languages' => [ 'en-bb' ],
        'name'      => 'Barbados'
    },
    'bd' => {
        'languages' => [ 'bn-bd', 'en' ],
        'name'      => 'Bangladesh'
    },
    'be' => {
        'languages' => [ 'nl-be', 'fr-be', 'de-be' ],
        'name'      => 'Belgium'
    },
    'bf' => {
        'languages' => [ 'fr-bf' ],
        'name'      => 'Burkina Faso'
    },
    'bg' => {
        'languages' => [ 'bg', 'tr-bg' ],
        'name'      => 'Bulgaria'
    },
    'bh' => {
        'languages' => [ 'ar-bh', 'en', 'fa', 'ur' ],
        'name'      => 'Bahrain'
    },
    'bi' => {
        'languages' => [ 'fr-bi', 'rn' ],
        'name'      => 'Burundi'
    },
    'bj' => {
        'languages' => [ 'fr-bj' ],
        'name'      => 'Benin'
    },
    'bl' => {
        'languages' => [ 'fr' ],
        'name'      => 'Saint Barthelemy'
    },
    'bm' => {
        'languages' => [ 'en-bm', 'pt' ],
        'name'      => 'Bermuda'
    },
    'bn' => {
        'languages' => [ 'ms-bn', 'en-bn' ],
        'name'      => 'Brunei'
    },
    'bo' => {
        'languages' => [ 'es-bo', 'qu', 'ay' ],
        'name'      => 'Bolivia'
    },
    'bq' => {
        'languages' => [ 'nl', 'pap', 'en' ],
        'name'      => 'Bonaire, Saint Eustatius and Saba '
    },
    'br' => {
        'languages' => [ 'pt-br', 'es', 'en', 'fr' ],
        'name'      => 'Brazil'
    },
    'bs' => {
        'languages' => [ 'en-bs' ],
        'name'      => 'Bahamas'
    },
    'bt' => {
        'languages' => [ 'dz' ],
        'name'      => 'Bhutan'
    },
    'bv' => {
        'languages' => [],
        'name'      => 'Bouvet Island'
    },
    'bw' => {
        'languages' => [ 'en-bw', 'tn-bw' ],
        'name'      => 'Botswana'
    },
    'by' => {
        'languages' => [ 'be', 'ru' ],
        'name'      => 'Belarus'
    },
    'bz' => {
        'languages' => [ 'en-bz', 'es' ],
        'name'      => 'Belize'
    },
    'ca' => {
        'languages' => [ 'en-ca', 'fr-ca', 'iu' ],
        'name'      => 'Canada'
    },
    'cc' => {
        'languages' => [ 'ms-cc', 'en' ],
        'name'      => 'Cocos Islands'
    },
    'cd' => {
        'languages' => [ 'fr-cd', 'ln', 'kg' ],
        'name'      => 'Democratic Republic of the Congo'
    },
    'cf' => {
        'languages' => [ 'fr-cf', 'sg', 'ln', 'kg' ],
        'name'      => 'Central African Republic'
    },
    'cg' => {
        'languages' => [ 'fr-cg', 'kg', 'ln-cg' ],
        'name'      => 'Republic of the Congo'
    },
    'ch' => {
        'languages' => [ 'de-ch', 'fr-ch', 'it-ch', 'rm' ],
        'name'      => 'Switzerland'
    },
    'ci' => {
        'languages' => [ 'fr-ci' ],
        'name'      => 'Ivory Coast'
    },
    'ck' => {
        'languages' => [ 'en-ck', 'mi' ],
        'name'      => 'Cook Islands'
    },
    'cl' => {
        'languages' => [ 'es-cl' ],
        'name'      => 'Chile'
    },
    'cm' => {
        'languages' => [ 'en-cm', 'fr-cm' ],
        'name'      => 'Cameroon'
    },
    'cn' => {
        'languages' => [ 'zh-cn', 'yue', 'wuu', 'dta', 'ug', 'za' ],
        'name'      => 'China'
    },
    'co' => {
        'languages' => [ 'es-co' ],
        'name'      => 'Colombia'
    },
    'cr' => {
        'languages' => [ 'es-cr', 'en' ],
        'name'      => 'Costa Rica'
    },
    'cs' => {
        'languages' => [ 'cu', 'hu', 'sq', 'sr' ],
        'name'      => 'Serbia and Montenegro'
    },
    'cu' => {
        'languages' => [ 'es-cu' ],
        'name'      => 'Cuba'
    },
    'cv' => {
        'languages' => [ 'pt-cv' ],
        'name'      => 'Cape Verde'
    },
    'cw' => {
        'languages' => [ 'nl', 'pap' ],
        'name'      => 'Curacao'
    },
    'cx' => {
        'languages' => [ 'en', 'zh', 'ms-cc' ],
        'name'      => 'Christmas Island'
    },
    'cy' => {
        'languages' => [ 'el-cy', 'tr-cy', 'en' ],
        'name'      => 'Cyprus'
    },
    'cz' => {
        'languages' => [ 'cs', 'sk' ],
        'name'      => 'Czech Republic'
    },
    'de' => {
        'languages' => [ 'de' ],
        'name'      => 'Germany'
    },
    'dj' => {
        'languages' => [ 'fr-dj', 'ar', 'so-dj', 'aa' ],
        'name'      => 'Djibouti'
    },
    'dk' => {
        'languages' => [ 'da-dk', 'en', 'fo', 'de-dk' ],
        'name'      => 'Denmark'
    },
    'dm' => {
        'languages' => [ 'en-dm' ],
        'name'      => 'Dominica'
    },
    'do' => {
        'languages' => [ 'es-do' ],
        'name'      => 'Dominican Republic'
    },
    'dz' => {
        'languages' => [ 'ar-dz' ],
        'name'      => 'Algeria'
    },
    'ec' => {
        'languages' => [ 'es-ec' ],
        'name'      => 'Ecuador'
    },
    'ee' => {
        'languages' => [ 'et', 'ru' ],
        'name'      => 'Estonia'
    },
    'eg' => {
        'languages' => [ 'ar-eg', 'en', 'fr' ],
        'name'      => 'Egypt'
    },
    'eh' => {
        'languages' => [ 'ar', 'mey' ],
        'name'      => 'Western Sahara'
    },
    'er' => {
        'languages' => [ 'aa-er', 'ar', 'tig', 'kun', 'ti-er' ],
        'name'      => 'Eritrea'
    },
    'es' => {
        'languages' => [ 'es-es', 'ca', 'gl', 'eu', 'oc' ],
        'name'      => 'Spain'
    },
    'et' => {
        'languages' => [ 'am', 'en-et', 'om-et', 'ti-et', 'so-et', 'sid' ],
        'name'      => 'Ethiopia'
    },
    'fi' => {
        'languages' => [ 'fi-fi', 'sv-fi', 'smn' ],
        'name'      => 'Finland'
    },
    'fj' => {
        'languages' => [ 'en-fj', 'fj' ],
        'name'      => 'Fiji'
    },
    'fk' => {
        'languages' => [ 'en-fk' ],
        'name'      => 'Falkland Islands'
    },
    'fm' => {
        'languages' =>
          [ 'en-fm', 'chk', 'pon', 'yap', 'kos', 'uli', 'woe', 'nkr', 'kpg' ],
        'name' => 'Micronesia'
    },
    'fo' => {
        'languages' => [ 'fo', 'da-fo' ],
        'name'      => 'Faroe Islands'
    },
    'fr' => {
        'languages' => [ 'fr-fr', 'frp', 'br', 'co', 'ca', 'eu', 'oc' ],
        'name'      => 'France'
    },
    'ga' => {
        'languages' => [ 'fr-ga' ],
        'name'      => 'Gabon'
    },
    'gb' => {
        'languages' => [ 'en-gb', 'cy-gb', 'gd' ],
        'name'      => 'United Kingdom'
    },
    'gd' => {
        'languages' => [ 'en-gd' ],
        'name'      => 'Grenada'
    },
    'ge' => {
        'languages' => [ 'ka', 'ru', 'hy', 'az' ],
        'name'      => 'Georgia'
    },
    'gf' => {
        'languages' => [ 'fr-gf' ],
        'name'      => 'French Guiana'
    },
    'gg' => {
        'languages' => [ 'en', 'fr' ],
        'name'      => 'Guernsey'
    },
    'gh' => {
        'languages' => [ 'en-gh', 'ak', 'ee', 'tw' ],
        'name'      => 'Ghana'
    },
    'gi' => {
        'languages' => [ 'en-gi', 'es', 'it', 'pt' ],
        'name'      => 'Gibraltar'
    },
    'gl' => {
        'languages' => [ 'kl', 'da-gl', 'en' ],
        'name'      => 'Greenland'
    },
    'gm' => {
        'languages' => [ 'en-gm', 'mnk', 'wof', 'wo', 'ff' ],
        'name'      => 'Gambia'
    },
    'gn' => {
        'languages' => [ 'fr-gn' ],
        'name'      => 'Guinea'
    },
    'gp' => {
        'languages' => [ 'fr-gp' ],
        'name'      => 'Guadeloupe'
    },
    'gq' => {
        'languages' => [ 'es-gq', 'fr' ],
        'name'      => 'Equatorial Guinea'
    },
    'gr' => {
        'languages' => [ 'el-gr', 'en', 'fr' ],
        'name'      => 'Greece'
    },
    'gs' => {
        'languages' => [ 'en' ],
        'name'      => 'South Georgia and the South Sandwich Islands'
    },
    'gt' => {
        'languages' => [ 'es-gt' ],
        'name'      => 'Guatemala'
    },
    'gu' => {
        'languages' => [ 'en-gu', 'ch-gu' ],
        'name'      => 'Guam'
    },
    'gw' => {
        'languages' => [ 'pt-gw', 'pov' ],
        'name'      => 'Guinea-Bissau'
    },
    'gy' => {
        'languages' => [ 'en-gy' ],
        'name'      => 'Guyana'
    },
    'hk' => {
        'languages' => [ 'zh-hk', 'yue', 'zh', 'en' ],
        'name'      => 'Hong Kong'
    },
    'hm' => {
        'languages' => [],
        'name'      => 'Heard Island and McDonald Islands'
    },
    'hn' => {
        'languages' => [ 'es-hn' ],
        'name'      => 'Honduras'
    },
    'hr' => {
        'languages' => [ 'hr-hr', 'sr' ],
        'name'      => 'Croatia'
    },
    'ht' => {
        'languages' => [ 'ht', 'fr-ht' ],
        'name'      => 'Haiti'
    },
    'hu' => {
        'languages' => [ 'hu-hu' ],
        'name'      => 'Hungary'
    },
    'id' => {
        'languages' => [ 'id', 'en', 'nl', 'jv' ],
        'name'      => 'Indonesia'
    },
    'ie' => {
        'languages' => [ 'en-ie', 'ga-ie' ],
        'name'      => 'Ireland'
    },
    'il' => {
        'languages' => [ 'he', 'ar-il', 'en-il' ],
        'name'      => 'Israel'
    },
    'im' => {
        'languages' => [ 'en', 'gv' ],
        'name'      => 'Isle of Man'
    },
    'in' => {
        'languages' => [
            'en-in', 'hi', 'bn',  'te',  'mr',  'ta',  'ur',  'gu',
            'kn',    'ml', 'or',  'pa',  'as',  'bh',  'sat', 'ks',
            'ne',    'sd', 'kok', 'doi', 'mni', 'sit', 'sa',  'fr',
            'lus',   'inc'
        ],
        'name' => 'India'
    },
    'io' => {
        'languages' => [ 'en-io' ],
        'name'      => 'British Indian Ocean Territory'
    },
    'iq' => {
        'languages' => [ 'ar-iq', 'ku', 'hy' ],
        'name'      => 'Iraq'
    },
    'ir' => {
        'languages' => [ 'fa-ir', 'ku' ],
        'name'      => 'Iran'
    },
    'is' => {
        'languages' => [ 'is', 'en', 'de', 'da', 'sv', 'no' ],
        'name'      => 'Iceland'
    },
    'it' => {
        'languages' => [ 'it-it', 'de-it', 'fr-it', 'sc', 'ca', 'co', 'sl' ],
        'name'      => 'Italy'
    },
    'je' => {
        'languages' => [ 'en', 'pt' ],
        'name'      => 'Jersey'
    },
    'jm' => {
        'languages' => [ 'en-jm' ],
        'name'      => 'Jamaica'
    },
    'jo' => {
        'languages' => [ 'ar-jo', 'en' ],
        'name'      => 'Jordan'
    },
    'jp' => {
        'languages' => [ 'ja' ],
        'name'      => 'Japan'
    },
    'ke' => {
        'languages' => [ 'en-ke', 'sw-ke' ],
        'name'      => 'Kenya'
    },
    'kg' => {
        'languages' => [ 'ky', 'uz', 'ru' ],
        'name'      => 'Kyrgyzstan'
    },
    'kh' => {
        'languages' => [ 'km', 'fr', 'en' ],
        'name'      => 'Cambodia'
    },
    'ki' => {
        'languages' => [ 'en-ki', 'gil' ],
        'name'      => 'Kiribati'
    },
    'km' => {
        'languages' => [ 'ar', 'fr-km' ],
        'name'      => 'Comoros'
    },
    'kn' => {
        'languages' => [ 'en-kn' ],
        'name'      => 'Saint Kitts and Nevis'
    },
    'kp' => {
        'languages' => [ 'ko-kp' ],
        'name'      => 'North Korea'
    },
    'kr' => {
        'languages' => [ 'ko-kr', 'en' ],
        'name'      => 'South Korea'
    },
    'kw' => {
        'languages' => [ 'ar-kw', 'en' ],
        'name'      => 'Kuwait'
    },
    'ky' => {
        'languages' => [ 'en-ky' ],
        'name'      => 'Cayman Islands'
    },
    'kz' => {
        'languages' => [ 'kk', 'ru' ],
        'name'      => 'Kazakhstan'
    },
    'la' => {
        'languages' => [ 'lo', 'fr', 'en' ],
        'name'      => 'Laos'
    },
    'lb' => {
        'languages' => [ 'ar-lb', 'fr-lb', 'en', 'hy' ],
        'name'      => 'Lebanon'
    },
    'lc' => {
        'languages' => [ 'en-lc' ],
        'name'      => 'Saint Lucia'
    },
    'li' => {
        'languages' => [ 'de-li' ],
        'name'      => 'Liechtenstein'
    },
    'lk' => {
        'languages' => [ 'si', 'ta', 'en' ],
        'name'      => 'Sri Lanka'
    },
    'lr' => {
        'languages' => [ 'en-lr' ],
        'name'      => 'Liberia'
    },
    'ls' => {
        'languages' => [ 'en-ls', 'st', 'zu', 'xh' ],
        'name'      => 'Lesotho'
    },
    'lt' => {
        'languages' => [ 'lt', 'ru', 'pl' ],
        'name'      => 'Lithuania'
    },
    'lu' => {
        'languages' => [ 'lb', 'de-lu', 'fr-lu' ],
        'name'      => 'Luxembourg'
    },
    'lv' => {
        'languages' => [ 'lv', 'ru', 'lt' ],
        'name'      => 'Latvia'
    },
    'ly' => {
        'languages' => [ 'ar-ly', 'it', 'en' ],
        'name'      => 'Libya'
    },
    'ma' => {
        'languages' => [ 'ar-ma', 'fr' ],
        'name'      => 'Morocco'
    },
    'mc' => {
        'languages' => [ 'fr-mc', 'en', 'it' ],
        'name'      => 'Monaco'
    },
    'md' => {
        'languages' => [ 'ro', 'ru', 'gag', 'tr' ],
        'name'      => 'Moldova'
    },
    'me' => {
        'languages' => [ 'sr', 'hu', 'bs', 'sq', 'hr', 'rom' ],
        'name'      => 'Montenegro'
    },
    'mf' => {
        'languages' => [ 'fr' ],
        'name'      => 'Saint Martin'
    },
    'mg' => {
        'languages' => [ 'fr-mg', 'mg' ],
        'name'      => 'Madagascar'
    },
    'mh' => {
        'languages' => [ 'mh', 'en-mh' ],
        'name'      => 'Marshall Islands'
    },
    'mk' => {
        'languages' => [ 'mk', 'sq', 'tr', 'rmm', 'sr' ],
        'name'      => 'Macedonia'
    },
    'ml' => {
        'languages' => [ 'fr-ml', 'bm' ],
        'name'      => 'Mali'
    },
    'mm' => {
        'languages' => [ 'my' ],
        'name'      => 'Myanmar'
    },
    'mn' => {
        'languages' => [ 'mn', 'ru' ],
        'name'      => 'Mongolia'
    },
    'mo' => {
        'languages' => [ 'zh', 'zh-mo', 'pt' ],
        'name'      => 'Macao'
    },
    'mp' => {
        'languages' => [ 'fil', 'tl', 'zh', 'ch-mp', 'en-mp' ],
        'name'      => 'Northern Mariana Islands'
    },
    'mq' => {
        'languages' => [ 'fr-mq' ],
        'name'      => 'Martinique'
    },
    'mr' => {
        'languages' => [ 'ar-mr', 'fuc', 'snk', 'fr', 'mey', 'wo' ],
        'name'      => 'Mauritania'
    },
    'ms' => {
        'languages' => [ 'en-ms' ],
        'name'      => 'Montserrat'
    },
    'mt' => {
        'languages' => [ 'mt', 'en-mt' ],
        'name'      => 'Malta'
    },
    'mu' => {
        'languages' => [ 'en-mu', 'bho', 'fr' ],
        'name'      => 'Mauritius'
    },
    'mv' => {
        'languages' => [ 'dv', 'en' ],
        'name'      => 'Maldives'
    },
    'mw' => {
        'languages' => [ 'ny', 'yao', 'tum', 'swk' ],
        'name'      => 'Malawi'
    },
    'mx' => {
        'languages' => [ 'es-mx' ],
        'name'      => 'Mexico'
    },
    'my' => {
        'languages' => [ 'ms-my', 'en', 'zh', 'ta', 'te', 'ml', 'pa', 'th' ],
        'name'      => 'Malaysia'
    },
    'mz' => {
        'languages' => [ 'pt-mz', 'vmw' ],
        'name'      => 'Mozambique'
    },
    'na' => {
        'languages' => [ 'en-na', 'af', 'de', 'hz', 'naq' ],
        'name'      => 'Namibia'
    },
    'nc' => {
        'languages' => [ 'fr-nc' ],
        'name'      => 'New Caledonia'
    },
    'ne' => {
        'languages' => [ 'fr-ne', 'ha', 'kr', 'dje' ],
        'name'      => 'Niger'
    },
    'nf' => {
        'languages' => [ 'en-nf' ],
        'name'      => 'Norfolk Island'
    },
    'ng' => {
        'languages' => [ 'en-ng', 'ha', 'yo', 'ig', 'ff' ],
        'name'      => 'Nigeria'
    },
    'ni' => {
        'languages' => [ 'es-ni', 'en' ],
        'name'      => 'Nicaragua'
    },
    'nl' => {
        'languages' => [ 'nl-nl', 'fy-nl' ],
        'name'      => 'Netherlands'
    },
    'no' => {
        'languages' => [ 'no', 'nb', 'nn', 'se', 'fi' ],
        'name'      => 'Norway'
    },
    'np' => {
        'languages' => [ 'ne', 'en' ],
        'name'      => 'Nepal'
    },
    'nr' => {
        'languages' => [ 'na', 'en-nr' ],
        'name'      => 'Nauru'
    },
    'nu' => {
        'languages' => [ 'niu', 'en-nu' ],
        'name'      => 'Niue'
    },
    'nz' => {
        'languages' => [ 'en-nz', 'mi' ],
        'name'      => 'New Zealand'
    },
    'om' => {
        'languages' => [ 'ar-om', 'en', 'bal', 'ur' ],
        'name'      => 'Oman'
    },
    'pa' => {
        'languages' => [ 'es-pa', 'en' ],
        'name'      => 'Panama'
    },
    'pe' => {
        'languages' => [ 'es-pe', 'qu', 'ay' ],
        'name'      => 'Peru'
    },
    'pf' => {
        'languages' => [ 'fr-pf', 'ty' ],
        'name'      => 'French Polynesia'
    },
    'pg' => {
        'languages' => [ 'en-pg', 'ho', 'meu', 'tpi' ],
        'name'      => 'Papua New Guinea'
    },
    'ph' => {
        'languages' => [ 'tl', 'en-ph', 'fil' ],
        'name'      => 'Philippines'
    },
    'pk' => {
        'languages' => [ 'ur-pk', 'en-pk', 'pa', 'sd', 'ps', 'brh' ],
        'name'      => 'Pakistan'
    },
    'pl' => {
        'languages' => [ 'pl' ],
        'name'      => 'Poland'
    },
    'pm' => {
        'languages' => [ 'fr-pm' ],
        'name'      => 'Saint Pierre and Miquelon'
    },
    'pn' => {
        'languages' => [ 'en-pn' ],
        'name'      => 'Pitcairn'
    },
    'pr' => {
        'languages' => [ 'en-pr', 'es-pr' ],
        'name'      => 'Puerto Rico'
    },
    'ps' => {
        'languages' => [ 'ar-ps' ],
        'name'      => 'Palestinian Territory'
    },
    'pt' => {
        'languages' => [ 'pt-pt', 'mwl' ],
        'name'      => 'Portugal'
    },
    'pw' => {
        'languages' => [ 'pau', 'sov', 'en-pw', 'tox', 'ja', 'fil', 'zh' ],
        'name'      => 'Palau'
    },
    'py' => {
        'languages' => [ 'es-py', 'gn' ],
        'name'      => 'Paraguay'
    },
    'qa' => {
        'languages' => [ 'ar-qa', 'es' ],
        'name'      => 'Qatar'
    },
    're' => {
        'languages' => [ 'fr-re' ],
        'name'      => 'Reunion'
    },
    'ro' => {
        'languages' => [ 'ro', 'hu', 'rom' ],
        'name'      => 'Romania'
    },
    'rs' => {
        'languages' => [ 'sr', 'hu', 'bs', 'rom' ],
        'name'      => 'Serbia'
    },
    'ru' => {
        'languages' => [
            'ru', 'tt',  'xal', 'cau', 'ady', 'kv',  'ce',  'tyv',
            'cv', 'udm', 'tut', 'mns', 'bua', 'myv', 'mdf', 'chm',
            'ba', 'inh', 'tut', 'kbd', 'krc', 'ava', 'sah', 'nog'
        ],
        'name' => 'Russia'
    },
    'rw' => {
        'languages' => [ 'rw', 'en-rw', 'fr-rw', 'sw' ],
        'name'      => 'Rwanda'
    },
    'sa' => {
        'languages' => [ 'ar-sa' ],
        'name'      => 'Saudi Arabia'
    },
    'sb' => {
        'languages' => [ 'en-sb', 'tpi' ],
        'name'      => 'Solomon Islands'
    },
    'sc' => {
        'languages' => [ 'en-sc', 'fr-sc' ],
        'name'      => 'Seychelles'
    },
    'sd' => {
        'languages' => [ 'ar-sd', 'en', 'fia' ],
        'name'      => 'Sudan'
    },
    'se' => {
        'languages' => [ 'sv-se', 'se', 'sma', 'fi-se' ],
        'name'      => 'Sweden'
    },
    'sg' => {
        'languages' => [ 'cmn', 'en-sg', 'ms-sg', 'ta-sg', 'zh-sg' ],
        'name'      => 'Singapore'
    },
    'sh' => {
        'languages' => [ 'en-sh' ],
        'name'      => 'Saint Helena'
    },
    'si' => {
        'languages' => [ 'sl', 'sh' ],
        'name'      => 'Slovenia'
    },
    'sj' => {
        'languages' => [ 'no', 'ru' ],
        'name'      => 'Svalbard and Jan Mayen'
    },
    'sk' => {
        'languages' => [ 'sk', 'hu' ],
        'name'      => 'Slovakia'
    },
    'sl' => {
        'languages' => [ 'en-sl', 'men', 'tem' ],
        'name'      => 'Sierra Leone'
    },
    'sm' => {
        'languages' => [ 'it-sm' ],
        'name'      => 'San Marino'
    },
    'sn' => {
        'languages' => [ 'fr-sn', 'wo', 'fuc', 'mnk' ],
        'name'      => 'Senegal'
    },
    'so' => {
        'languages' => [ 'so-so', 'ar-so', 'it', 'en-so' ],
        'name'      => 'Somalia'
    },
    'sr' => {
        'languages' => [ 'nl-sr', 'en', 'srn', 'hns', 'jv' ],
        'name'      => 'Suriname'
    },
    'ss' => {
        'languages' => [ 'en' ],
        'name'      => 'South Sudan'
    },
    'st' => {
        'languages' => [ 'pt-st' ],
        'name'      => 'Sao Tome and Principe'
    },
    'sv' => {
        'languages' => [ 'es-sv' ],
        'name'      => 'El Salvador'
    },
    'sx' => {
        'languages' => [ 'nl', 'en' ],
        'name'      => 'Sint Maarten'
    },
    'sy' => {
        'languages' => [ 'ar-sy', 'ku', 'hy', 'arc', 'fr', 'en' ],
        'name'      => 'Syria'
    },
    'sz' => {
        'languages' => [ 'en-sz', 'ss-sz' ],
        'name'      => 'Swaziland'
    },
    'tc' => {
        'languages' => [ 'en-tc' ],
        'name'      => 'Turks and Caicos Islands'
    },
    'td' => {
        'languages' => [ 'fr-td', 'ar-td', 'sre' ],
        'name'      => 'Chad'
    },
    'tf' => {
        'languages' => [ 'fr' ],
        'name'      => 'French Southern Territories'
    },
    'tg' => {
        'languages' => [ 'fr-tg', 'ee', 'hna', 'kbp', 'dag', 'ha' ],
        'name'      => 'Togo'
    },
    'th' => {
        'languages' => [ 'th', 'en' ],
        'name'      => 'Thailand'
    },
    'tj' => {
        'languages' => [ 'tg', 'ru' ],
        'name'      => 'Tajikistan'
    },
    'tk' => {
        'languages' => [ 'tkl', 'en-tk' ],
        'name'      => 'Tokelau'
    },
    'tl' => {
        'languages' => [ 'tet', 'pt-tl', 'id', 'en' ],
        'name'      => 'East Timor'
    },
    'tm' => {
        'languages' => [ 'tk', 'ru', 'uz' ],
        'name'      => 'Turkmenistan'
    },
    'tn' => {
        'languages' => [ 'ar-tn', 'fr' ],
        'name'      => 'Tunisia'
    },
    'to' => {
        'languages' => [ 'to', 'en-to' ],
        'name'      => 'Tonga'
    },
    'tr' => {
        'languages' => [ 'tr-tr', 'ku', 'diq', 'az', 'av' ],
        'name'      => 'Turkey'
    },
    'tt' => {
        'languages' => [ 'en-tt', 'hns', 'fr', 'es', 'zh' ],
        'name'      => 'Trinidad and Tobago'
    },
    'tv' => {
        'languages' => [ 'tvl', 'en', 'sm', 'gil' ],
        'name'      => 'Tuvalu'
    },
    'tw' => {
        'languages' => [ 'zh-tw', 'zh', 'nan', 'hak' ],
        'name'      => 'Taiwan'
    },
    'tz' => {
        'languages' => [ 'sw-tz', 'en', 'ar' ],
        'name'      => 'Tanzania'
    },
    'ua' => {
        'languages' => [ 'uk', 'ru-ua', 'rom', 'pl', 'hu' ],
        'name'      => 'Ukraine'
    },
    'ug' => {
        'languages' => [ 'en-ug', 'lg', 'sw', 'ar' ],
        'name'      => 'Uganda'
    },
    'um' => {
        'languages' => [ 'en-um' ],
        'name'      => 'United States Minor Outlying Islands'
    },
    'us' => {
        'languages' => [ 'en-us', 'es-us', 'haw', 'fr' ],
        'name'      => 'United States'
    },
    'uy' => {
        'languages' => [ 'es-uy' ],
        'name'      => 'Uruguay'
    },
    'uz' => {
        'languages' => [ 'uz', 'ru', 'tg' ],
        'name'      => 'Uzbekistan'
    },
    'va' => {
        'languages' => [ 'la', 'it', 'fr' ],
        'name'      => 'Vatican'
    },
    'vc' => {
        'languages' => [ 'en-vc', 'fr' ],
        'name'      => 'Saint Vincent and the Grenadines'
    },
    've' => {
        'languages' => [ 'es-ve' ],
        'name'      => 'Venezuela'
    },
    'vg' => {
        'languages' => [ 'en-vg' ],
        'name'      => 'British Virgin Islands'
    },
    'vi' => {
        'languages' => [ 'en-vi' ],
        'name'      => 'U.S. Virgin Islands'
    },
    'vn' => {
        'languages' => [ 'vi', 'en', 'fr', 'zh', 'km' ],
        'name'      => 'Vietnam'
    },
    'vu' => {
        'languages' => [ 'bi', 'en-vu', 'fr-vu' ],
        'name'      => 'Vanuatu'
    },
    'wf' => {
        'languages' => [ 'wls', 'fud', 'fr-wf' ],
        'name'      => 'Wallis and Futuna'
    },
    'ws' => {
        'languages' => [ 'sm', 'en-ws' ],
        'name'      => 'Samoa'
    },
    'xk' => {
        'languages' => [ 'sq', 'sr' ],
        'name'      => 'Kosovo'
    },
    'ye' => {
        'languages' => [ 'ar-ye' ],
        'name'      => 'Yemen'
    },
    'yt' => {
        'languages' => [ 'fr-yt' ],
        'name'      => 'Mayotte'
    },
    'za' => {
        'languages' => [
            'zu', 'xh', 'af', 'nso', 'en-za', 'tn',
            'st', 'ts', 'ss', 've',  'nr'
        ],
        'name' => 'South Africa'
    },
    'zm' => {
        'languages' => [ 'en-zm', 'bem', 'loz', 'lun', 'lue', 'ny', 'toi' ],
        'name'      => 'Zambia'
    },
    'zw' => {
        'languages' => [ 'en-zw', 'sn', 'nr', 'nd' ],
        'name'      => 'Zimbabwe'
    }
);
%lang_charset = (
    'af' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Afrikaans',
        'windows'   => 'windows-1252'
    },
    'am' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Amharic',
        'windows'   => 'utf-8'
    },
    'ar' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic',
        'windows'   => 'windows-1256'
    },
    'ar-ae' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - United Arab Emirates',
        'windows'   => 'windows-1256'
    },
    'ar-bh' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - Bahrain',
        'windows'   => 'windows-1256'
    },
    'ar-dz' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - Algeria',
        'windows'   => 'windows-1256'
    },
    'ar-eg' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - Egypt',
        'windows'   => 'windows-1256'
    },
    'ar-iq' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - Iraq',
        'windows'   => 'windows-1256'
    },
    'ar-jo' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - Jordan',
        'windows'   => 'windows-1256'
    },
    'ar-kw' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - Kuwait',
        'windows'   => 'windows-1256'
    },
    'ar-lb' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - Lebanon',
        'windows'   => 'windows-1256'
    },
    'ar-ly' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - Libya',
        'windows'   => 'windows-1256'
    },
    'ar-ma' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - Morocco',
        'windows'   => 'windows-1256'
    },
    'ar-om' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - Oman',
        'windows'   => 'windows-1256'
    },
    'ar-qa' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - Qatar',
        'windows'   => 'windows-1256'
    },
    'ar-sa' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - Saudi Arabia',
        'windows'   => 'windows-1256'
    },
    'ar-sy' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - Syria',
        'windows'   => 'windows-1256'
    },
    'ar-tn' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - Tunisia',
        'windows'   => 'windows-1256'
    },
    'ar-ye' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Arabic - Yemen',
        'windows'   => 'windows-1256'
    },
    'as' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Assamese',
        'windows'   => 'utf-8'
    },
    'az' => {
        'linux'     => 'iso-8859-9',
        'macintosh' => 'x-mac-turkish',
        'name'      => 'Azeri',
        'windows'   => 'windows-1254'
    },
    'az-cyrl' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-cyrillic',
        'name'      => 'Azeri - Cyrillic',
        'windows'   => 'windows-1251'
    },
    'az-latn' => {
        'linux'     => 'iso-8859-9',
        'macintosh' => 'x-mac-turkish',
        'name'      => 'Azeri - Latin',
        'windows'   => 'windows-1254'
    },
    'be' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-cyrillic',
        'name'      => 'Belarusian',
        'windows'   => 'windows-1251'
    },
    'bg' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-cyrillic',
        'name'      => 'Bulgarian',
        'windows'   => 'windows-1251'
    },
    'bn' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Bengali - India',
        'windows'   => 'utf-8'
    },
    'bo' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Tibetan',
        'windows'   => 'utf-8'
    },
    'bs' => {
        'linux'     => 'iso-8859-2',
        'macintosh' => 'x-mac-ce',
        'name'      => 'Bosnian',
        'windows'   => 'windows-1250'
    },
    'bs-cyrl' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-cyrillic',
        'name'      => 'Bosnian - Cyrillic',
        'windows'   => 'windows-1251'
    },
    'bs-latn' => {
        'linux'     => 'iso-8859-2',
        'macintosh' => 'x-mac-ce',
        'name'      => 'Bosnian - Latin',
        'windows'   => 'windows-1250'
    },
    'ca' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Catalan',
        'windows'   => 'windows-1252'
    },
    'cs' => {
        'linux'     => 'iso-8859-2',
        'macintosh' => 'x-mac-ce',
        'name'      => 'Czech',
        'windows'   => 'windows-1250'
    },
    'cy' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Welsh',
        'windows'   => 'windows-1252'
    },
    'da' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Danish',
        'windows'   => 'windows-1252'
    },
    'de' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'German',
        'windows'   => 'windows-1252'
    },
    'de-at' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'German - Austria',
        'windows'   => 'windows-1252'
    },
    'de-ch' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'German - Switzerland',
        'windows'   => 'windows-1252'
    },
    'de-de' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'German - Germany',
        'windows'   => 'windows-1252'
    },
    'de-li' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'German - Liechtenstein',
        'windows'   => 'windows-1252'
    },
    'de-lu' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'German - Luxembourg',
        'windows'   => 'windows-1252'
    },
    'dv' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Divehi; Dhivehi; Maldivian',
        'windows'   => 'utf-8'
    },
    'el' => {
        'linux'     => 'iso-8859-7',
        'macintosh' => 'x-mac-greek',
        'name'      => 'Greek',
        'windows'   => 'windows-1253'
    },
    'en' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'English',
        'windows'   => 'windows-1252'
    },
    'en-au' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'English - Australia',
        'windows'   => 'windows-1252'
    },
    'en-bz' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'English - Belize',
        'windows'   => 'windows-1252'
    },
    'en-ca' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'English - Canada',
        'windows'   => 'windows-1252'
    },
    'en-cb' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'English - Caribbean',
        'windows'   => 'windows-1252'
    },
    'en-gb' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'English - Great Britain',
        'windows'   => 'windows-1252'
    },
    'en-ie' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'English - Ireland',
        'windows'   => 'windows-1252'
    },
    'en-in' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'English - India',
        'windows'   => 'windows-1252'
    },
    'en-jm' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'English - Jamaica',
        'windows'   => 'windows-1252'
    },
    'en-nz' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'English - New Zealand',
        'windows'   => 'windows-1252'
    },
    'en-ph' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'English - Phillippines',
        'windows'   => 'windows-1252'
    },
    'en-tt' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'English - Trinidad',
        'windows'   => 'windows-1252'
    },
    'en-us' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'English - United States',
        'windows'   => 'windows-1252'
    },
    'en-za' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'English - Southern Africa',
        'windows'   => 'windows-1252'
    },
    'en-zw' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'English - Zimbabwe',
        'windows'   => 'windows-1252'
    },
    'es-ar' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Argentina',
        'windows'   => 'windows-1252'
    },
    'es-bo' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Bolivia',
        'windows'   => 'windows-1252'
    },
    'es-cl' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Chile',
        'windows'   => 'windows-1252'
    },
    'es-co' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Colombia',
        'windows'   => 'windows-1252'
    },
    'es-cr' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Costa Rica',
        'windows'   => 'windows-1252'
    },
    'es-do' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Dominican Republic',
        'windows'   => 'windows-1252'
    },
    'es-ec' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Ecuador',
        'windows'   => 'windows-1252'
    },
    'es-es' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Spain (Traditional)',
        'windows'   => 'windows-1252'
    },
    'es-gt' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Guatemala',
        'windows'   => 'windows-1252'
    },
    'es-hn' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Honduras',
        'windows'   => 'windows-1252'
    },
    'es-mx' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Mexico',
        'windows'   => 'windows-1252'
    },
    'es-ni' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Nicaragua',
        'windows'   => 'windows-1252'
    },
    'es-pa' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Panama',
        'windows'   => 'windows-1252'
    },
    'es-pe' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Peru',
        'windows'   => 'windows-1252'
    },
    'es-pr' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Puerto Rico',
        'windows'   => 'windows-1252'
    },
    'es-py' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Paraguay',
        'windows'   => 'windows-1252'
    },
    'es-sv' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - El Salvador',
        'windows'   => 'windows-1252'
    },
    'es-uy' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Uruguay',
        'windows'   => 'windows-1252'
    },
    'es-ve' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Spanish - Venezuela',
        'windows'   => 'windows-1252'
    },
    'et' => {
        'linux'     => 'iso-8859-4',
        'macintosh' => 'windows-1257',
        'name'      => 'Estonian',
        'windows'   => 'windows-1257'
    },
    'eu' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Basque',
        'windows'   => 'windows-1252'
    },
    'fa' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-farsi',
        'name'      => 'Farsi - Persian',
        'windows'   => 'windows-1256'
    },
    'fi' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Finnish',
        'windows'   => 'windows-1252'
    },
    'fo' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Faroese',
        'windows'   => 'windows-1252'
    },
    'fr' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'French',
        'windows'   => 'windows-1252'
    },
    'fr-be' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'French - Belgium',
        'windows'   => 'windows-1252'
    },
    'fr-ca' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'French - Canada',
        'windows'   => 'windows-1252'
    },
    'fr-cg' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'French - Congo',
        'windows'   => 'windows-1252'
    },
    'fr-ch' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'French - Switzerland',
        'windows'   => 'windows-1252'
    },
    'fr-cm' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'French - Cameroon',
        'windows'   => 'windows-1252'
    },
    'fr-fr' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'French - France',
        'windows'   => 'windows-1252'
    },
    'fr-lu' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'French - Luxembourg',
        'windows'   => 'windows-1252'
    },
    'fr-ma' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'French - Morocco',
        'windows'   => 'windows-1252'
    },
    'fr-mc' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'French - Monaco',
        'windows'   => 'windows-1252'
    },
    'fr-ml' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'French - Mali',
        'windows'   => 'windows-1252'
    },
    'fr-sn' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'French - Senegal',
        'windows'   => 'windows-1252'
    },
    'fy' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Frisian - Netherlands',
        'windows'   => 'windows-1252'
    },
    'gd' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Gaelic - Scotland',
        'windows'   => 'windows-1252'
    },
    'gd-ie' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Gaelic - Ireland',
        'windows'   => 'windows-1252'
    },
    'gl' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Galician',
        'windows'   => 'windows-1252'
    },
    'gn' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Guarani - Paraguay',
        'windows'   => 'utf-8'
    },
    'gu' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Gujarati',
        'windows'   => 'utf-8'
    },
    'he' => {
        'linux'     => 'iso-8859-8',
        'macintosh' => 'x-mac-hebrew',
        'name'      => 'Hebrew',
        'windows'   => 'windows-1255'
    },
    'hi' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Hindi',
        'windows'   => 'utf-8'
    },
    'hr' => {
        'linux'     => 'iso-8859-2',
        'macintosh' => 'x-mac-croatian',
        'name'      => 'Croatian',
        'windows'   => 'windows-1250'
    },
    'hu' => {
        'linux'     => 'iso-8859-2',
        'macintosh' => 'x-mac-ce',
        'name'      => 'Hungarian',
        'windows'   => 'windows-1250'
    },
    'hy' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Armenian',
        'windows'   => 'utf-8'
    },
    'id' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Indonesian',
        'windows'   => 'windows-1252'
    },
    'ig' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Igbo - Nigeria',
        'windows'   => 'utf-8'
    },
    'is' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-islandic',
        'name'      => 'Icelandic',
        'windows'   => 'windows-1252'
    },
    'it' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Italian',
        'windows'   => 'windows-1252'
    },
    'it-ch' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Italian - Switzerland',
        'windows'   => 'windows-1252'
    },
    'it-it' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Italian - Italy',
        'windows'   => 'windows-1252'
    },
    'ja' => {
        'linux'     => 'iso-2022-jp',
        'macintosh' => 'x-mac-japanese',
        'name'      => 'Japanese',
        'windows'   => 'windows-932'
    },
    'ka' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Georgian',
        'windows'   => 'utf-8'
    },
    'kk' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-cyrillic',
        'name'      => 'Kazakh',
        'windows'   => 'windows-1251'
    },
    'km' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Khmer',
        'windows'   => 'utf-8'
    },
    'kn' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Kannada',
        'windows'   => 'utf-8'
    },
    'ko' => {
        'linux'     => 'iiso-2022-kr',
        'macintosh' => 'x-mac-korean',
        'name'      => 'Korean',
        'windows'   => 'windows-949'
    },
    'kok' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Konkani',
        'windows'   => 'utf-8'
    },
    'ks' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Kashmiri',
        'windows'   => 'utf-8'
    },
    'ky' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-cyrillic',
        'name'      => 'Kyrgyz - Cyrillic',
        'windows'   => 'windows-1251'
    },
    'la' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Latin',
        'windows'   => 'windows-1252'
    },
    'lo' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Lao',
        'windows'   => 'utf-8'
    },
    'lt' => {
        'linux'     => 'iso-8859-4',
        'macintosh' => 'windows-1257',
        'name'      => 'Lithuanian',
        'windows'   => 'windows-1257'
    },
    'lv' => {
        'linux'     => 'iso-8859-4',
        'macintosh' => 'windows-1257',
        'name'      => 'Latvian',
        'windows'   => 'windows-1257'
    },
    'mi' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Maori',
        'windows'   => 'windows-1252'
    },
    'mk' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-cyrillic',
        'name'      => 'FYRO Macedonia',
        'windows'   => 'windows-1251'
    },
    'ml' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Malayalam',
        'windows'   => 'utf-8'
    },
    'mn' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-cyrillic',
        'name'      => 'Mongolian',
        'windows'   => 'windows-1251'
    },
    'mni' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Manipuri',
        'windows'   => 'utf-8'
    },
    'mr' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Marathi',
        'windows'   => 'utf-8'
    },
    'ms' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Malay',
        'windows'   => 'windows-1252'
    },
    'ms-bn' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Malay - Brunei',
        'windows'   => 'windows-1252'
    },
    'ms-my' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Malay - Malaysia',
        'windows'   => 'windows-1252'
    },
    'mt' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Maltese',
        'windows'   => 'windows-1252'
    },
    'my' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Burmese',
        'windows'   => 'utf-8'
    },
    'nb' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Norwegian - Bokml',
        'windows'   => 'windows-1252'
    },
    'ne' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Nepali',
        'windows'   => 'utf-8'
    },
    'nl' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Dutch',
        'windows'   => 'windows-1252'
    },
    'nl-be' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Dutch - Belgium',
        'windows'   => 'windows-1252'
    },
    'nl-nl' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Dutch - Netherlands',
        'windows'   => 'windows-1252'
    },
    'nn' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Norwegian - Nynorsk',
        'windows'   => 'windows-1252'
    },
    'ns' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Sesotho (Sutu)',
        'windows'   => 'windows-1252'
    },
    'or' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Oriya',
        'windows'   => 'utf-8'
    },
    'pa' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Punjabi',
        'windows'   => 'utf-8'
    },
    'pl' => {
        'linux'     => 'iso-8859-2',
        'macintosh' => 'x-mac-ce',
        'name'      => 'Polish',
        'windows'   => 'windows-1250'
    },
    'pt-br' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Portuguese - Brazil',
        'windows'   => 'windows-1252'
    },
    'pt-pt' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Portuguese - Portugal',
        'windows'   => 'windows-1252'
    },
    'rm' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Raeto-Romance',
        'windows'   => 'windows-1252'
    },
    'ro' => {
        'linux'     => 'iso-8859-2',
        'macintosh' => 'x-mac-romanian',
        'name'      => 'Romanian - Romania',
        'windows'   => 'windows-1250'
    },
    'ro-mo' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-cyrillic',
        'name'      => 'Romanian - Moldova',
        'windows'   => 'windows-1251'
    },
    'ru' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-cyrillic',
        'name'      => 'Russian',
        'windows'   => 'windows-1251'
    },
    'ru-mo' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-cyrillic',
        'name'      => 'Russian - Moldova',
        'windows'   => 'windows-1251'
    },
    'sa' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Sanskrit',
        'windows'   => 'utf-8'
    },
    'sb' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Sorbian',
        'windows'   => 'windows-1252'
    },
    'sd' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Sindhi',
        'windows'   => 'windows-1256'
    },
    'se' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-sami',
        'name'      => 'Sami Lappish',
        'windows'   => 'windows-1252'
    },
    'si' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Sinhala; Sinhalese',
        'windows'   => 'utf-8'
    },
    'sk' => {
        'linux'     => 'iso-8859-2',
        'macintosh' => 'x-mac-ce',
        'name'      => 'Slovak',
        'windows'   => 'windows-1250'
    },
    'sl' => {
        'linux'     => 'iso-8859-2',
        'macintosh' => 'x-mac-ce',
        'name'      => 'Slovenian',
        'windows'   => 'windows-1250'
    },
    'so' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Somali',
        'windows'   => 'windows-1252'
    },
    'sq' => {
        'linux'     => 'iso-8859-2',
        'macintosh' => 'x-mac-ce',
        'name'      => 'Albanian',
        'windows'   => 'windows-1250'
    },
    'sr' => {
        'linux'     => 'iso-8859-2',
        'macintosh' => 'x-mac-ce',
        'name'      => 'Serbian',
        'windows'   => 'windows-1250'
    },
    'sr-cyrl' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-cyrillic',
        'name'      => 'Serbian - Cyrillic',
        'windows'   => 'windows-1251'
    },
    'sr-latn' => {
        'linux'     => 'iso-8859-2',
        'macintosh' => 'x-mac-ce',
        'name'      => 'Serbian - Latin',
        'windows'   => 'windows-1250'
    },
    'sv-fi' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Swedish - Finland',
        'windows'   => 'windows-1252'
    },
    'sv-se' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Swedish - Sweden',
        'windows'   => 'windows-1252'
    },
    'sw' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Swahili',
        'windows'   => 'windows-1252'
    },
    'syr' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Syriac',
        'windows'   => 'utf-8'
    },
    'ta' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Tamil',
        'windows'   => 'utf-8'
    },
    'te' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Telugu',
        'windows'   => 'utf-8'
    },
    'tg' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-cyrillic',
        'name'      => 'Tajik',
        'windows'   => 'windows-1251'
    },
    'th' => {
        'linux'     => 'iso-8859-11',
        'macintosh' => 'x-mac-thai',
        'name'      => 'Thai',
        'windows'   => 'windows-874'
    },
    'tk' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-cyrillic',
        'name'      => 'Turkmen',
        'windows'   => 'windows-1251'
    },
    'tn' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Setsuana',
        'windows'   => 'windows-1252'
    },
    'tr' => {
        'linux'     => 'iso-8859-9',
        'macintosh' => 'x-mac-turkish',
        'name'      => 'Turkish',
        'windows'   => 'windows-1254'
    },
    'ts' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Tsonga',
        'windows'   => 'windows-1252'
    },
    'tt' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-cyrillic',
        'name'      => 'Tatar',
        'windows'   => 'windows-1251'
    },
    'uk' => {
        'linux'     => 'iso-8859-5',
        'macintosh' => 'x-mac-ukrainian',
        'name'      => 'Ukrainian',
        'windows'   => 'windows-1251'
    },
    'ur' => {
        'linux'     => 'iso-8859-6',
        'macintosh' => 'x-mac-arabic',
        'name'      => 'Urdu',
        'windows'   => 'windows-1256'
    },
    'uz-uz' => {
        'linux'     => 'iso-8859-9',
        'macintosh' => 'x-mac-turkish',
        'name'      => 'Uzbek - Latin',
        'windows'   => 'windows-1254'
    },
    've' => {
        'linux'     => 'utf-8',
        'macintosh' => 'utf-8',
        'name'      => 'Venda',
        'windows'   => 'utf-8'
    },
    'vi' => {
        'linux'     => 'viscii',
        'macintosh' => 'x-mac-vietnamese',
        'name'      => 'Vietnamese',
        'windows'   => 'windows-1258'
    },
    'xh' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Xhosa',
        'windows'   => 'windows-1252'
    },
    'yi' => {
        'linux'     => 'iso-8859-8',
        'macintosh' => 'x-mac-hebrew',
        'name'      => 'Yiddish',
        'windows'   => 'windows-1255'
    },
    'zh' => {
        'linux'     => 'gb18030',
        'macintosh' => 'x-mac-simp',
        'name'      => 'Chinese',
        'windows'   => 'windows-936'
    },
    'zh-cn' => {
        'linux'     => 'gb18030',
        'macintosh' => 'x-mac-simp',
        'name'      => 'Chinese - China',
        'windows'   => 'windows-936'
    },
    'zh-hk' => {
        'linux'     => 'big5',
        'macintosh' => 'x-mac-chinesetrad',
        'name'      => 'Chinese - Hong Kong SAR',
        'windows'   => 'windows-950'
    },
    'zh-mo' => {
        'linux'     => 'big5',
        'macintosh' => 'x-mac-chinesetrad',
        'name'      => 'Chinese - Macau SAR',
        'windows'   => 'windows-950'
    },
    'zh-sg' => {
        'linux'     => 'gb18030',
        'macintosh' => 'x-mac-simp',
        'name'      => 'Chinese - Singapore',
        'windows'   => 'windows-936'
    },
    'zh-tw' => {
        'linux'     => 'big5',
        'macintosh' => 'x-mac-chinesetrad',
        'name'      => 'Chinese - Taiwan',
        'windows'   => 'windows-950'
    },
    'zu' => {
        'linux'     => 'iso-8859-1',
        'macintosh' => 'x-mac-roman',
        'name'      => 'Zulu',
        'windows'   => 'windows-1252'
    }
);


=head1 LICENSE

This is released under the Artistic
License. See L<perlartistic>.

=head1 AUTHOR

Lyle Hopkins - L<http://www.cosmicperl.com/>

Development kindly sponsored by - L<http://www.greenrope.com/>

=head1 SEE ALSO

L<Encode::Detect::Upload>

=cut


1;
