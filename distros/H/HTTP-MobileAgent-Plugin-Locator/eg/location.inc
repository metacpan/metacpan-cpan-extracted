[%- linkname = linkname || 'Send Location Information' -%]
[%- IF agent.is_docomo # DoCoMo -%]
[%- USE u = URL( back_url, query_params ) -%]
[%- IF agent.gps_compliant # GPS -%]<a href="[% u %]" lcs>[% linkname %]</a>[%- ELSE # location -%]<a href="http://w1m.docomo.ne.jp/cp/iarea?ecode=OPENAREACODE&msn=OPENAREAKEY&posinfo=1&nl=[% u %]">[% linkname %]</a>[% END -%]
[%- ELSIF agent.is_ezweb # EZweb -%]
[%- new_url = '/path/to/program/param1/' _ query_params.param1 _ '/param2/' _ query_params.param2;
    back_url = back_url.replace( '/search/location', new_url );
    USE u = URL( back_url ) -%]
[%- IF agent.gps_compliant # GPS -%]<a href="device:gpsone?url=[% u %]&ver=1&datum=0&unit=0&acry=0&number=0">[% linkname %]</a>[%- ELSE # location -%]<a href="device:location?url=[% u %]">[% linkname %]</a>[%- END -%]
[%- ELSIF agent.is_softbank # SoftBank -%]
[%- IF agent.gps_compliant # GPS -%]
[%- new_url = '/path/to/program/param1/' _ query_params.param1 _ '/param2/' _ query_params.param2;
    back_url = back_url.replace( '/search/location', new_url );
    USE u = URL( back_url ) -%]
<a href="location:auto?url=[% u %]">[% linkname %]</a>
[%- ELSE # location -%]
[%- USE u = URL( back_url, query_params ) -%]
<a href="[% u %]" z>[% linkname %]</a>
[%- END -%]
[%- ELSIF agent.is_airh_phone # Willcom -%]
[%- USE u = URL( back_url, query_params ) -%]
[%- new_url = '/path/to/program/param1/' _ query_params.param1 _ '/param2/' _ query_params.param2;
    back_url = back_url.replace( '/search/location', new_url );
    USE u = URL( back_url ) -%]
<a href="http://location.request/dummy.cgi?my=[% u %]&pos=$location">[% linkname %]</a>
[%- END -%]
