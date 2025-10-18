use XML::LibXML;
use URI::Escape;
use MIME::Base64;

sub saml_key_proxy_private_enc {
    "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA2vzoUiQ4GsM5qLjoxslEDKj+RrPh/A743JCWe1Hbadjd5yD4
gPwmJUxMF+MJcQlo/TkmKbTonPdIoAqDknbUxfFTntp0VkdKrB64xr0Stpy7123h
Pszat3SbU3RYypdobEcuSAS77w9X1KnkRL1+CIe59qSsghO3l3b2IJ6qPFXdx/cr
o7+K3O7w8wAEJ9KmxA0KdiZpSFgTAqfNDSKx8NLwZOeDpsHouAxy1E2kine+9ESB
TRAM2PgiGZvU5JA1SZscdEg3wTftJxxPFnAJMwtqM3IVC6B+TqsIP5Wlk1PQQqH7
5gjtBYDVduynBwU+l/UUmp1aDRZupuH8PF51pwIDAQABAoIBAF11xqkX8CHr4/XQ
RPhh+Xr1vN/r8ayjry5jPvYOr3fzKHF2LtjNxHHyqB8htGvbukUoWNM/9G7ZUtOK
6TBfKtv37NpFHZWdA4+F5RJcq1nodnqw2Ir23vmg+JGbfDGqgNSFZIk0DAkxISkQ
AO4deWamloVfLoitZZNtIAo37SumJ1JBiqLOTsTL/bVQCYTkFG0zZ+XYi9+JrIMb
UZj5BEnWzUYiqg3dsGg+USO84811U4DjMmfkJrOBTkd1VucJhNpWbaFl8uzpO4/r
yBPGSsIwzuomP7ePotK+ZWrDmYAHej7ZaZ6KvJzDgMWTIzqLj7jXAn8h5H0ix1Az
QGCufxECgYEA/ewbcN+aB54NDaiCmvnvCVMYA+KcI3OldbvJY7iXHduJrRmEvoSB
Hm9NRx02gb45XtRL46SlnRIXWnbmdfsAqSlYVNrI62Qd7PVeLVon9fK2V88AnHDA
Z5Rt6A9kDhYPmvRC7vlN5Al/lWeDxwfOWzRLmsGYfBe0fGLoyX5p3LUCgYEA3Mef
fzKOPcj9NozLStttYxvWwcYA/ELO81dhujgFGJG774CeR2hwJL/tFg868gLNL1Io
b5LKxasp6V2EkMEaI1RPOkQIldVZCju+UJnmmC4fWpkdhivElzWIRIOCoIRqNSNu
HIoihdl/j62yWGArpXVuBr4Wm70eZUTYz5B6HmsCgYEAvxrwHCdtmcYONPVaNqFc
kjwDmwj2Uog7Qzyt+Wt38HTGTY0jJvA67Vj/ZEJMP6GXNBO7efz02B5BjUhncuwS
Nz5yyIpRJTgYfbq9woxT/vtI2RVmdFc3t70yarEKsL9Rx2GG7qybPsEXUK6zsxvg
5yuYq0SBKwP8RpF6egu2SPECgYAa2Iczb1FOf/8SQAKEQrRFZeAyRcJe6jzB6DEw
9JjiCO6CS/BzHGbugQvyL73qKZ8LjwDtuDrB2HNLNhzlgSWNgDX2DsnAdmXSUbtt
j5kzjgAwAwhNBUttW4wLULZ0kEVd2sYL4FwcTHsvXF6gUmlcQDA1z61uGIv2om1+
p8HBqwKBgQCRDCfLGk4HCtz5nIg3JDnRXILXzdNFUfRDdcj7zZlF4BQ9ryn4SGrO
LrY+vU6d9cIVPcG8yei6s7zLCDED4tcdUxL1a1XvWUr5eVglVARkGu739Qta2G5c
ZnWPY16ZL7eafmAm8QRKMNh1So9dnEe8MzBMvHBno67JFVSWjyNY/A==
-----END RSA PRIVATE KEY-----";
}

sub saml_key_proxy_private_sig {
    "-----BEGIN RSA PRIVATE KEY-----
MIIEpgIBAAKCAQEAztmb1JZk/agkYYm23D4dqaLS4EKHKrjO4eBvwtWZLexAGR1K
DpcrHqLyqJoal+q4A8drI7lxElSt6xRKJ4DIxQM1jqRcmE6EzdL6BfTaRace3zIu
hjDSQUZJdtFtlJynQT1cJbx5ZYhqZbYANm9NZRcYZ5gWeyF9nl41xA79AMuYlpt7
eWDR8cnQJXwV790991FQ9yA2BBgTdSKkFqZ72P4lWu4shz3JCGf5hyq03hCHQ7bs
fpgAdCrbQPTuJNFtS599ClMu+AcRcwJcS233pHd306PRHCXn3Eapq6gEoHxgLVNp
+luAIhRA9EaOnZ0nVkFwFKn3vLXzV01iTliMeQIDAQABAoIBAQCEQj+RPlh0l/4r
H5L8X/s3bBTJr8AdYO1nH8pWGZ1H77dMV53yllXL0QS3KVG3sSzXvbqTrQ7PWbWa
ie6gM4gr8FFeU1mhSRNBR5T2Ggk2YBUtQTjeNHk7o2V1w5L9YuzOmh1BQ7Gbag4d
2rFoHOKvsIS6OFSnhlJ74GEgazT6PA0I4Y3Bue6tJEzdITVtU0ZWnKEBOWvxb/XV
6fCFgVF1IfYx5ufHFmJA/PTm6cDyXyMTOk50vRVqSF1R50y/Ew18BGNQmeflVMWr
oEy821feLz2+C4hdyhtx3grVLVH4iyHzt0+0hFi6YpkEv4uSJGI5HT43GpjJbZGz
lAgAVFMBAoGBAPUTiYyzckOGx/cYzTUpk3EV+eaLJ8KtEr6DJMdLhHKhORwjXl51
E0L3D6xLJhugEglrNHQ6c34AIJIudq4sz5qwuOvMKARkK7jBc0OZTkixr7dQdYeI
HfR46aQCoFhBdBvPVr8TzoX35qr41VibyaBUi6NkHSeAqjPZwPsJTwTVAoGBANgR
4ytCOChToKA/6hjj80WJpOH60DIshptimQu3LmhJV+GCEBaDkGrAUTpYeHqSvY3c
oYsKG6Z6HTOzW1zD6LkAQMrJFZwqHVs7iqWRIjIqKNcCyDM8JCStZdbq3J7xq7vr
Rdv+xGqt+Er3Fsr2rvF3/NEo0rQPCxfx1SeDCAsVAoGBAInFY+vu7Os9F6i3DpU2
PCa0ffm2fLGZ7hGfU8udjmWKcLp6v5BGLH/Wt77ZuCCLidg1phU4zrgkhirnZ9xe
YI7LjgkwicZ+MX35cjysMC/5g5h/6LI6OOy4FFAZEd7LXORNWKyuC8mQJOI0ZGsd
mOlC3gUKQMF2OThQz4XQI9XJAoGBAIA5PUKyrXjhB/WReG8E951QrdSdb2gXHFqi
DIjzUEr7G3fsI3f44382Wf3x+q1i37KMOCG3Aemtlh7UVWebq0P+bnTpGDXwmDNI
BmNy2YRDmLDgKcad7iUF8eW0wvBgIrYGTRLdAdr9GtgCAji4Y+FQf2vwefn443B2
RzSHggJxAoGBAKOHVA6JohafcaGBNEdEUgFX+bheBAxVsYhtnMgiEKK2Zvlf4jc5
/iBp1VzYrAmZXHLXkI2BkxXBX3rsRJ04IoCnF0VCOLGBilu3u/eg+c0S1RAbTxWh
onzAhxhnMjGAHRHCOlWVYosZQ9m4BI9Aq0COlbs/qDk0EfTT4FpO93Gd
-----END RSA PRIVATE KEY-----";
}

sub saml_key_proxy_public_enc {
    "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2vzoUiQ4GsM5qLjoxslE
DKj+RrPh/A743JCWe1Hbadjd5yD4gPwmJUxMF+MJcQlo/TkmKbTonPdIoAqDknbU
xfFTntp0VkdKrB64xr0Stpy7123hPszat3SbU3RYypdobEcuSAS77w9X1KnkRL1+
CIe59qSsghO3l3b2IJ6qPFXdx/cro7+K3O7w8wAEJ9KmxA0KdiZpSFgTAqfNDSKx
8NLwZOeDpsHouAxy1E2kine+9ESBTRAM2PgiGZvU5JA1SZscdEg3wTftJxxPFnAJ
MwtqM3IVC6B+TqsIP5Wlk1PQQqH75gjtBYDVduynBwU+l/UUmp1aDRZupuH8PF51
pwIDAQAB
-----END PUBLIC KEY-----";
}

sub saml_key_proxy_public_sig {
    "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAztmb1JZk/agkYYm23D4d
qaLS4EKHKrjO4eBvwtWZLexAGR1KDpcrHqLyqJoal+q4A8drI7lxElSt6xRKJ4DI
xQM1jqRcmE6EzdL6BfTaRace3zIuhjDSQUZJdtFtlJynQT1cJbx5ZYhqZbYANm9N
ZRcYZ5gWeyF9nl41xA79AMuYlpt7eWDR8cnQJXwV790991FQ9yA2BBgTdSKkFqZ7
2P4lWu4shz3JCGf5hyq03hCHQ7bsfpgAdCrbQPTuJNFtS599ClMu+AcRcwJcS233
pHd306PRHCXn3Eapq6gEoHxgLVNp+luAIhRA9EaOnZ0nVkFwFKn3vLXzV01iTliM
eQIDAQAB
-----END PUBLIC KEY-----";
}

sub saml_key_proxy_cert_enc {
    "-----BEGIN CERTIFICATE-----
MIIDbTCCAlWgAwIBAgIUHhmuu1i4Oodctizp3ivZwdPADtEwDQYJKoZIhvcNAQEL
BQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM
GEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDAgFw0yNTA5MDkwODEwNTJaGA8yMTI1
MDgxNjA4MTA1MlowRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUx
ITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBANr86FIkOBrDOai46MbJRAyo/kaz4fwO+NyQlntR
22nY3ecg+ID8JiVMTBfjCXEJaP05Jim06Jz3SKAKg5J21MXxU57adFZHSqweuMa9
Eracu9dt4T7M2rd0m1N0WMqXaGxHLkgEu+8PV9Sp5ES9fgiHufakrIITt5d29iCe
qjxV3cf3K6O/itzu8PMABCfSpsQNCnYmaUhYEwKnzQ0isfDS8GTng6bB6LgMctRN
pIp3vvREgU0QDNj4Ihmb1OSQNUmbHHRIN8E37SccTxZwCTMLajNyFQugfk6rCD+V
pZNT0EKh++YI7QWA1XbspwcFPpf1FJqdWg0Wbqbh/DxedacCAwEAAaNTMFEwHQYD
VR0OBBYEFLW/evNijEugkS2kqexwN2Ydp0LMMB8GA1UdIwQYMBaAFLW/evNijEug
kS2kqexwN2Ydp0LMMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEB
AKIMOBJ/uplUIDArX6UygIdpFa+I/T9earwx6fLYVH1vM/fWJTPiijL5s+a/eftf
MJ8hy/Ac3UTZg63X10mPeLMjnWv/nLsttp6fifBz86g+xFx8FZHRt6KxrWC45PwE
XaYbm9r79kjRtKfTzO05I6VOQaip5+3qGMPc9JCfJ+sxnRNl9E3kiNA1Sitzs6Mp
Y2R0kEvyHCEJa0j5nFuyZpCD3kau1pxsNa44QuGW0egjO61ri96Bn72xAUtDuozw
ikVPX5/wIyC9oMXdUyJXN7incU0n6cIiza70X7wlgehRkSsbrHUWGUs5/ASShOo0
t1Grxc3Vfbw3Fqir6wn46OE=
-----END CERTIFICATE-----";
}

sub saml_key_proxy_cert_sig {
    "-----BEGIN CERTIFICATE-----
MIIDbTCCAlWgAwIBAgIUFscP0cOkJ/U2YuZkgeHTxh0o4BgwDQYJKoZIhvcNAQEL
BQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM
GEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDAgFw0yNTA4MDExNDAyMjJaGA8yMTI1
MDcwODE0MDIyMlowRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUx
ITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBAM7Zm9SWZP2oJGGJttw+Hami0uBChyq4zuHgb8LV
mS3sQBkdSg6XKx6i8qiaGpfquAPHayO5cRJUresUSieAyMUDNY6kXJhOhM3S+gX0
2kWnHt8yLoYw0kFGSXbRbZScp0E9XCW8eWWIamW2ADZvTWUXGGeYFnshfZ5eNcQO
/QDLmJabe3lg0fHJ0CV8Fe/dPfdRUPcgNgQYE3UipBame9j+JVruLIc9yQhn+Ycq
tN4Qh0O27H6YAHQq20D07iTRbUuffQpTLvgHEXMCXEtt96R3d9Oj0Rwl59xGqauo
BKB8YC1TafpbgCIUQPRGjp2dJ1ZBcBSp97y181dNYk5YjHkCAwEAAaNTMFEwHQYD
VR0OBBYEFA4wi6itTPYB2iQ3nSCAys3qp8iZMB8GA1UdIwQYMBaAFA4wi6itTPYB
2iQ3nSCAys3qp8iZMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEB
AKzSKAeAq5/9iypK67rJbEidZjoID9v8IgyzmOmrCG4dwJhmmN7ZdJuwFE50x9id
mdTCJMJg4ZMKAcFDEHGNKi/YIDQglnF8E3fG5sJ7nGJc44fAlkpp01LSsjYLRB+j
X3ax2PDbYRc/qnkrMVXcqj19PYY/cBCn2epyWuG7Za6RuLXT35aEkvrnmZpvfBgl
drcvJIwl29yZRpjNp3xLTdc5F1tF3OD2i5TQiYmdMpM4qSZ2Tz4IT3PKs45ZtjdS
lWJX7ivL+rq+TbiY680PL69IyTxWphBy9YYmGHVUTZJUxMMSKiI7CpDPQQ13F1wX
FnQH+J3thbkj8O6gqWZ5X3E=
-----END CERTIFICATE-----";
}

sub saml_key_idp_private_enc {
    "-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAnfKBDG/K0TnGT7Xu8q1N45sNWvIK91SqNg8nvN2uVeKoHADT
csus5Xn3id5+8Q9TuMFsW9kIEeXiaPKXQa9ryfSNDhWDWloNkpGEeWif2BnHUu46
Abu1UBWb0mH6VwcG1PR4qHruLis1odjQ1qnVDNfSEASVIppEBYjDX203ypmURIzU
6h53GRRRlf1BLWkbVn9ysmDeR57Xw5Rsx/+tBlcnMrkv/40DSUkehQIl2JmlFrl2
Caik+gU4pd20apA/pNLjBZF0OmGoS08AIR5NMd0KFa6CwZUUSHJqH5GFy5Y2yl4l
g8K0klAS9q7L7aXI+eFQZhkwidjpxXnHPyxIGQIDAQABAoIBAHnfqjX3eO8SfnP5
NURp90Td2mNHirCn0qLd9NKl1ySMPR1GgeH9SQ7Umu32EcteAUL5dOw2PiTZVmeW
cKINgsWVftXUQcOQ4xIqWKb51QUBdy0FhxrZRSFjWxXt5iYK1PmzHfsax/g1/S9C
RnqtFyjOy1bywkSt9jiy+9YBR2B7BDhLHlILbijWn5zaecaV4YA+L1UK4M/mehdb
+0FVPavbGpnlqBRTY+7YXfZ/mRPCfn5DvO9lW1O0pJMmNdBh9kmm3DxHf6AkK47a
43gO/dRWiWo2rZ/+Jw7uyqOb23U0MydP7kia0p3tzCUBPsrlgnichYG5RNFp0wqy
3VT1TYECgYEA0Y9vENy1jJd+s7WbGrsRtSKxfZgtJr0yjSlQVYrIlwbZSGn+ndxq
V2vVlwIgLX3pz6T40BMfk6SNx08jjy0Sgn6OAM0ILrinno8yWcSAMCmfCU0S/3O1
55bqtcnk4XTHBHzJ5OrnrPaW5ourvJz0lcWEKMg3BXxLzaF6ZRy85nECgYEAwPMD
LNAKLCDrUMyYFOpPyPLe7wvszcFvPipGgerSgFP1c6N7xaMUdHDYqBfuis1khPGF
YcMHeNBYmzX6yEGbp3lrB4PHpUySmTU3mv3u9I05aahInK21gXum3uRkCWyyIF6V
T/qeszl9mVOCp0CC4eG3IMVpaD0UKDEHVhERYCkCgYAjuTPRyA4a3Wh38ilysRkf
q75eDqcDx5Tqg3RyYKo5NK2troP9HSnzpSpQB8i8eI53G0RfFCN5479XjqIdMi3J
mRFUCZ+vd0L7wKVwsBK6Ix49U6o9adhElnGEc9pUpLeYiD1SjMjZr1+iBYVNLeRz
86vH1/mpMbsqXrCis/dvwQKBgGttomHr/w3s0jftget7PirrFrbP0+wHfDGHhjRF
kyhCFtJovrwefYALaIXGtVjw3LusYZA570oT7pGUb2naJZkMYEwR0jG1vZWx7KDO
K6JbkxDB0pPxn7JVL2bAkPYyX8boAohCSOQO6WBZ/8+xem3bp4OGhpa0EyoBik0g
OaVpAoGATj4SyYsE10hGT676iie8zy3fi5IPC3E+x4QlVuusaLtuY8LJA50stjtx
gUa/JAKlZZL+gvzvOviQIxyfIChXOdTt5uiOYkdHJDbAF3NSrji7hrXq4v8UZv75
8hBrwJZIpy6y01dRlrriHmPRtEq1pk7JX2uUg0sP5g4BEcsaCbc=
-----END RSA PRIVATE KEY----- ";
}

sub saml_key_idp_private_sig {
    "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAtR/wgDqWB4Maho5V6TjcL/NbNfjgIh7GcgkrB5RZcVT1GTej
JlMjUQdgBKBuZXQN+7/29P6UcGq1kYalURq6S8SpeJ1ofp5rBEoD/TIkvU0JOcid
65wp+fdzXGXsfiZvHraU74jSCgjP/wqfVGRyBIQzB0SIxSpnrsigqNsE1E94toDM
x4wovjHu/9ABAImREV7Sz83OeFF00/sghrjTEJOD/gHf04JCn9MgNOqvSTysr9LX
Wg/oUKQDEYeTq9ux6pq/oqv1MxwONbSZPtN5yD41mi+hT8Rh+W8Je8rsiML4VMxz
sb1l9303asw6suo5bLTISKNSbu1nt1NkpNxzywIDAQABAoIBAQCQkbvPPfP+bwC/
IeEk1IO7qkzFWa7czR+safD0jc6OjTdNN4F716Q6yt4zEzLKu8VliiW+C23EBQiD
7asKf4DvdTun0ExVtHDK7aEdeealSlXwz1ZtdypyILbtq1UGo/rR0v4x601rQPl0
IrBmFf6D6FkqleNtLJmxguXpoVfLdYKNwkxH2ux+GOA9r2o5pUCQmJGDap5YWRuQ
uB71ewJjVWujaL3e1ac/5cP7/tqWmgAiOaN8sYdD6+oWOR47bHj8JKcMBSl4y2QC
dL31cGmmf5KqBbtISki3RXfHHjT7E3Z85CbESkKTZlEb1ar3XmepY6Z7V5UO16oz
fFE5R6khAoGBAOl9Qb+qYVVO5ugE65ORjYVeuXykANhM9ssiY5a6zuAakWzw7Zv3
k6PXm9p7azlEXAlTnTXVwHYMyuuzZDvQ8LRV1iBOdPuIkUAmaQ5K9ASD7VcoHexh
k8DAKf9Ln7sTRaMdvgceRNczOmJOBIEpTZkssA/jVGXZsoyTWYl1en/ZAoGBAMaW
RnNbSNprEV2b8UeAJ6i77c4SXwu1I8X2NLtiLScb1ETBjfrdHmdlJglfyd/0gmhH
p/43Ku2iGUoY5KtuOI6QmahrJYQscRQhoj252VXadG6fNWWAlpgdCm9houhHb5BF
3zge/bTr0anUe9EA7Z/ymav12rEouoNjIlhI9C5DAoGATR85a2SMt8/TB0owwdJu
62GpZNkLCmcJkXkvaecUVAOSi2hdI4o4MwMRkK35cbX5rH74y4JqCtQY5pefgP53
sykzDAK+MyMdzxGg2764MRGegI5Yq+5jDmSquo+xF+q6srEtRk6iMG7UVwosBLmu
zuxqzySoiOfKSRKWnYe3SakCgYEAwWMkVkAmETXE4oDzFSsS8/mW2l//mPocTTK3
JWe1CunJ6+8FYbAlZJEW2ngismp8+CoXybNVpbZ+pC7buKoMf6EHUgCNt0pEEFO0
mCG9KSMk0XlPWXpArP9S4yaUq1itpzSz7QYZES+4rIcU0HLz9RgeWFyCTJWaFErc
7laVG9sCgYBKOtk5WlIOP4BxSd2y4cYzohgwTZIs1/2kTEn1u4eH73M1xvAlHHFB
wSF5QXgDKJ8pPAOhNWpdLO/PdtnQn91nOvTNc+ShJZzjdbneUdQVpWpoBf72uA+N
6rIVf1JBUL2p7HFHaGdUZC7KGQ+yv6ZHrE1+7202nuDvJdvGEEdFsQ==
-----END RSA PRIVATE KEY-----";
}

sub saml_key_idp_public_enc {
    "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnfKBDG/K0TnGT7Xu8q1N
45sNWvIK91SqNg8nvN2uVeKoHADTcsus5Xn3id5+8Q9TuMFsW9kIEeXiaPKXQa9r
yfSNDhWDWloNkpGEeWif2BnHUu46Abu1UBWb0mH6VwcG1PR4qHruLis1odjQ1qnV
DNfSEASVIppEBYjDX203ypmURIzU6h53GRRRlf1BLWkbVn9ysmDeR57Xw5Rsx/+t
BlcnMrkv/40DSUkehQIl2JmlFrl2Caik+gU4pd20apA/pNLjBZF0OmGoS08AIR5N
Md0KFa6CwZUUSHJqH5GFy5Y2yl4lg8K0klAS9q7L7aXI+eFQZhkwidjpxXnHPyxI
GQIDAQAB
-----END PUBLIC KEY----- ";
}

sub saml_key_idp_public_sig {
    "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtR/wgDqWB4Maho5V6Tjc
L/NbNfjgIh7GcgkrB5RZcVT1GTejJlMjUQdgBKBuZXQN+7/29P6UcGq1kYalURq6
S8SpeJ1ofp5rBEoD/TIkvU0JOcid65wp+fdzXGXsfiZvHraU74jSCgjP/wqfVGRy
BIQzB0SIxSpnrsigqNsE1E94toDMx4wovjHu/9ABAImREV7Sz83OeFF00/sghrjT
EJOD/gHf04JCn9MgNOqvSTysr9LXWg/oUKQDEYeTq9ux6pq/oqv1MxwONbSZPtN5
yD41mi+hT8Rh+W8Je8rsiML4VMxzsb1l9303asw6suo5bLTISKNSbu1nt1NkpNxz
ywIDAQAB
-----END PUBLIC KEY----- ";
}

sub saml_key_idp_cert_enc {
    "-----BEGIN CERTIFICATE-----
MIIDbTCCAlWgAwIBAgIUKagKPBppVRRYwcgzg5xGHPQBO8wwDQYJKoZIhvcNAQEL
BQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM
GEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDAgFw0yNTA5MDkwODExMTJaGA8yMTI1
MDgxNjA4MTExMlowRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUx
ITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBAJ3ygQxvytE5xk+17vKtTeObDVryCvdUqjYPJ7zd
rlXiqBwA03LLrOV594nefvEPU7jBbFvZCBHl4mjyl0Gva8n0jQ4Vg1paDZKRhHlo
n9gZx1LuOgG7tVAVm9Jh+lcHBtT0eKh67i4rNaHY0Nap1QzX0hAElSKaRAWIw19t
N8qZlESM1OoedxkUUZX9QS1pG1Z/crJg3kee18OUbMf/rQZXJzK5L/+NA0lJHoUC
JdiZpRa5dgmopPoFOKXdtGqQP6TS4wWRdDphqEtPACEeTTHdChWugsGVFEhyah+R
hcuWNspeJYPCtJJQEvauy+2lyPnhUGYZMInY6cV5xz8sSBkCAwEAAaNTMFEwHQYD
VR0OBBYEFDoYeBGs9qjH9DWBjWuLZlpgxUHzMB8GA1UdIwQYMBaAFDoYeBGs9qjH
9DWBjWuLZlpgxUHzMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEB
AHmwxWBvgwHsbgjByiAvlMc71AGe3KtBPomddEwbR0a4F/YHBh03MSIbkRzyy+N5
9bYPzkE0eDk8CH6S19gWJLYlauVjWuPwD5qfn2pk4B0Pxm+PGSCdcXCp9gfX2H1G
wV7db5yF5esm9sT8h26tCsF1pES0gqsgM+/7BZWYfMt7KRrBdtP/J8rdw3UrpIMD
5+KZOxj/2b/OZkeK9xXsNJcXnAS2XxVOghXsGFrK7I7RQZad0mpHTNOywORb8D0y
RMr5jii8f2/FhAG6YA5c8Bmxd0Hu8vEtR8psf5HEt4jMlzawVfVBS3V4RKdrPMvb
7AA0s1Lbzan5JuWwi3Z7tC0=
-----END CERTIFICATE-----";
}

sub saml_key_idp_cert_sig {
    "-----BEGIN CERTIFICATE-----
MIIDbTCCAlWgAwIBAgIUXsAX6Z/sTIq+w08CtE4HRuEdf2EwDQYJKoZIhvcNAQEL
BQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM
GEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDAgFw0yNTA4MDExNDAzMzVaGA8yMTI1
MDcwODE0MDMzNVowRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUx
ITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBALUf8IA6lgeDGoaOVek43C/zWzX44CIexnIJKweU
WXFU9Rk3oyZTI1EHYASgbmV0Dfu/9vT+lHBqtZGGpVEaukvEqXidaH6eawRKA/0y
JL1NCTnIneucKfn3c1xl7H4mbx62lO+I0goIz/8Kn1RkcgSEMwdEiMUqZ67IoKjb
BNRPeLaAzMeMKL4x7v/QAQCJkRFe0s/NznhRdNP7IIa40xCTg/4B39OCQp/TIDTq
r0k8rK/S11oP6FCkAxGHk6vbseqav6Kr9TMcDjW0mT7Tecg+NZovoU/EYflvCXvK
7IjC+FTMc7G9Zfd9N2rMOrLqOWy0yEijUm7tZ7dTZKTcc8sCAwEAAaNTMFEwHQYD
VR0OBBYEFNBDjE4qyY/dQTYHuG83e+nfiyXyMB8GA1UdIwQYMBaAFNBDjE4qyY/d
QTYHuG83e+nfiyXyMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEB
AD25y0JCSM42jZkkikqxL1alyW7KRm8llH3iw9uo9YqoUFZJCbF4dyVbjzTOGVIH
1d/felt2q5Ntcl+VtccODIjg2GpM6QteY4hq0mFy2Kwp8drR4HPryFOfhkxruPD4
Pp4BI9HbFZouc9lpEPxsfiWrqbpKSrPFsxCnq2gfz7LiM4K7/chXl1nvBsk2jfpp
qHx6YO+btmJX4VQnkYaAMENA93FtXZASqt3dNI7GuqOi/7NmUAEDx+Gh2XF6WB3Q
7ZugYlhGdFm/idQidpf5zNwNk2WMQ8RBlROKecgqEfUhpLeDziOek4cbsWbG2voz
yf+fBOtOrWK7VpWeIkMLJZY=
-----END CERTIFICATE-----";
}

sub saml_key_sp_private_enc {
    "-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAsRaod2RZ8hMFBl+VhsnhyPM8l/Fj1obnBxfQIaWuHFIFfXiG
e/CYHuZ5QJQLnZxHMJX6LL3Sh+Usog3p0jpijpcg0QgfBSEkfopKTgReYN8DiDIl
l0rV1XdTni7E85Nd1YyNy3ui/ZD+UShWwqu6jLVLR+QUm+/1LIKYb3OCBTvOlY7x
HoP6NSU1+Mr+YzGBUacdO2vnNxe/PQhxIeP1zO0njuqGHkwEpy8rUWRZbbDn31Tm
Kjqlhgtsz5HPhbRaYEExhyepKgBiNz+RyxtYXVhuG8OrWQDoS5gYHSjdw1CTJyix
eJwyoqA9RGYguG5nh9zndi3LWAh7Z0lx+tIz+wIDAQABAoIBAEkZrk8iiJKJ0WAx
IrsyKNbXuWKLTYgnxcRCyzKofrfID+YcU39j8JeI0fKbajQUZ7qhnlTLwtU//+2h
SqzyVu6/add/v7ZRWQw3L7cGzKK2THHzKVtLk/t7N3QroDdf1LMrQvkFP2HmcWS0
/yN62hXtXHb/qpY4Nn+6JQyUpM5dkv8S/QjDl2NTdyWrXKzWp+4I3QLQ20f4zym+
ir7RennziMc0HlQNcTjGAUbFULtdqEfSFWhNK7UjiRY+S0XV2xJIbGjnxUQH62fS
w1ZzYsF7sBtoSckvfL4WfGbylhOVnliU05RLU2c67PRjj1Gskoslq1Ow/3DHR7rI
BSBpV8ECgYEA1eHfcog7xQGDkW+cshJtFPFx+9MegB58gFW1rl0rn+tfbexvoSEA
7G7EOTyaU6OAI+8StiRT6AYTgEU7PMM9zDykdGIWj3h0OpHGA86xhEiiaaM2DDRv
/DEKRVlEdmRLLLY28pJVHOMYomia3mb2VKZGg2VfGtSfjg1GXD3I8OECgYEA0/X0
U55KjZ1JQTPUgFc1WK1NxX9MaH+NcpDaolEUy3Qf3QTbfws+a9K3vwCn7EpQhrfs
I6RVUtwFdCyfl/jzBY9Gykkg03sMgW7Qw2SCCsSt05M+jDtBbNJ7esP6PAeKFvXZ
ZWhdeiAa4kM/P6gtvZXQ4tY4LkSbcd6b0SzzFFsCgYBjMsusFzuBd95JyfZnMNye
5gzzu0teKMWd0CLfqB7foQ81sH9lwCTpg8ZGtbDuMdrwz6ViDR9NceQBjhqXaAZ1
f3rW79d+22Ms9wdcJLV4oSeSzzv2FSwLT8NvvqNeNc4YArshbnVDXKDEUrfhhueh
Ay2ZK58clpkaDVYg2hckgQKBgG3KuhtSI/YE4fwXN9yez7A2XNGPZem/IGqWo9lu
PGJCrXqT2IqPLW82gB083r6jo+CUhonTxqqb82tA7g4PUvqvQ5Dmnk1NMKYe255K
gp3HUO8GF2EWFIak5Hcr6oOLuDi6cjh3/euTk7ld8fYsTD0mzEOjiQhWW1p5X6bT
LLp/AoGAHvkxA1NM1HJ3myAREbwNXxRy/nhNt4mwMkZ6hPQsW/Eg/3r7j6MJOFrm
U8AJJjDGKe6nlXhhnMoQfJzAc0cYNgjktmJXW27fHGIwt/2QwYNFHPK3s7HTrfH6
7T4XKT3yGeeeyC2soKJQPlGB+ETdIUnXa7eo9KVWtMTgISyx1Qk=
-----END RSA PRIVATE KEY----- ";
}

sub saml_key_sp_private_sig {
    "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAu4iToYAEmWQxgZDihGVzMMql1elPn37domWcvXeU2E4yt2hh
5jkQHiFjgodfOlNeRIw5QJVlUBwr+CQvbaKRFXd7BrOhQIDC0TZPRVB0XHarUtsC
uDekN4/2GKSzHsoToKUVPWq9thsuek3xkpsJGZNX7bglfEc9+QQpYTqN1rkdN1PV
U0epNMokFFGho5pLRqLUV5+I/QXAL49jfTjaSxsp4UndTI8/+mGSRSq+nrT2zyQR
M/vkj5vR9ZVz67HO/+Wk3Mx6RAwkVcMdgMAqCq8odmbI0yCRZiTL9ybKWRKqWJoK
J0p5+Q2fPEBPupQZR09Jt/JPuLVSsGfCxi9NqwIDAQABAoIBABE0Cjb6g3F+23vD
SsRSeiqzrFrfOEqtXK+VGrfWzHS7V7Ozg6eW/H+HGJXUzUuQcklfg7EFA3JB41a0
GxW3oA+UElkfCV/dcAG5NbRqGQKScEz9glZb5FikgDLqiPP+HabS/gvQSu71t2HI
3KxSRJdwCNTp26Z28pxxYUpmELTtxd9vlHjffit2Mnt2uc8hOtFHdNavfYwvYH7o
bmlckp7b/JVOy2Yy21O94ZWkE498jXyn71Gr+V1cnJ0RrmYbhQqIvFpFHj98Pf4O
if3c4YmBcZ4t7PUsZUYF3ooWt8k/mdigQC3D6p80OKe+wUTYKcCN0ZdFbiURv9pg
CsqLh+ECgYEA9vA+9QfzvXC7S5yXgTkuRiusPlNye/AiyA/0oGjmjFZ1YNsT7awH
6BjW6WE+rS4elKJu1GaefM/cDguH4ZmJc+eKgi4LDCqYw9rr9les3aneBc8demd3
O/Ej1Pud1QxXArBNfBYo08vEqwST9P89clJC5090U6bGK2E0rTVu1w0CgYEAwmpG
9LbOFeGCPmwX7Avuk7tQQfRSV6q9TFZo+HxDfKYvxec846l1vBenY2rrgYhtolYJ
YS795LYgbSWRxGfgr1GuIbP5GsjHy6/1o6bS8M++GJ7KHArb0QLAYyQweqqb164A
NvHJkveueWnxzeOlD9j2fcjEnBHwTnqjG+17CZcCgYEAqMXawa4FsNxzpmIISpHC
RsNindZ60Kp3mzUMhPYtXI1a/C+/lxmU7dTMTgXgyIxU6lF6XkEk4TlPtWm8HTzK
7SS7Te4aLt6OOo5N57hUtct7q4y7IQXGQHm3e8HdRdeBQJ0u2Dhs/xSt/hTK6w/n
91Kx11Y+s02w88UkM53pe6ECgYAF/UYwVc1liSv9BlF6WSfBb1zam09KGh1405Sq
SxG9LlV8cFJE5TyWTdg/TNTyiaRvAt2JG+yAdkfrdOPXvCeE3yxRJ30+IP9evA4C
O6p19sBxe7rYQFFjUAVjSIMh1E22yEqDZtGB8JV0chob8K5uHY4CdAPylu7jTA3o
V1maAwKBgQCSGQ3yzsk4EGN2xd/JdgGDzhKyTZTQKMWYqQcsYxRAQ7Paj7u+Wkgv
dBeKcI0HwgpLy5ZohSd2erqieIsW0pEbJWCmos4IcO8tgNfEOa5WXYdyLbj5tFwt
ctu4/BJdijqfpMAtG8pv6k09gYjfASVytXmydGcs/0rVKYCRQA8Tow==
-----END RSA PRIVATE KEY----- ";
}

sub saml_key_sp_public_enc {
    "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsRaod2RZ8hMFBl+Vhsnh
yPM8l/Fj1obnBxfQIaWuHFIFfXiGe/CYHuZ5QJQLnZxHMJX6LL3Sh+Usog3p0jpi
jpcg0QgfBSEkfopKTgReYN8DiDIll0rV1XdTni7E85Nd1YyNy3ui/ZD+UShWwqu6
jLVLR+QUm+/1LIKYb3OCBTvOlY7xHoP6NSU1+Mr+YzGBUacdO2vnNxe/PQhxIeP1
zO0njuqGHkwEpy8rUWRZbbDn31TmKjqlhgtsz5HPhbRaYEExhyepKgBiNz+RyxtY
XVhuG8OrWQDoS5gYHSjdw1CTJyixeJwyoqA9RGYguG5nh9zndi3LWAh7Z0lx+tIz
+wIDAQAB
-----END PUBLIC KEY-----";
}

sub saml_key_sp_public_sig {
    "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAu4iToYAEmWQxgZDihGVz
MMql1elPn37domWcvXeU2E4yt2hh5jkQHiFjgodfOlNeRIw5QJVlUBwr+CQvbaKR
FXd7BrOhQIDC0TZPRVB0XHarUtsCuDekN4/2GKSzHsoToKUVPWq9thsuek3xkpsJ
GZNX7bglfEc9+QQpYTqN1rkdN1PVU0epNMokFFGho5pLRqLUV5+I/QXAL49jfTja
Sxsp4UndTI8/+mGSRSq+nrT2zyQRM/vkj5vR9ZVz67HO/+Wk3Mx6RAwkVcMdgMAq
Cq8odmbI0yCRZiTL9ybKWRKqWJoKJ0p5+Q2fPEBPupQZR09Jt/JPuLVSsGfCxi9N
qwIDAQAB
-----END PUBLIC KEY----- ";
}

sub saml_key_sp_cert_enc {
    "-----BEGIN CERTIFICATE-----
MIIDbTCCAlWgAwIBAgIUOA3efx8MRvHM5iY9EGO12QF4iJQwDQYJKoZIhvcNAQEL
BQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM
GEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDAgFw0yNTA5MDkwODExMDFaGA8yMTI1
MDgxNjA4MTEwMVowRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUx
ITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBALEWqHdkWfITBQZflYbJ4cjzPJfxY9aG5wcX0CGl
rhxSBX14hnvwmB7meUCUC52cRzCV+iy90oflLKIN6dI6Yo6XINEIHwUhJH6KSk4E
XmDfA4gyJZdK1dV3U54uxPOTXdWMjct7ov2Q/lEoVsKruoy1S0fkFJvv9SyCmG9z
ggU7zpWO8R6D+jUlNfjK/mMxgVGnHTtr5zcXvz0IcSHj9cztJ47qhh5MBKcvK1Fk
WW2w599U5io6pYYLbM+Rz4W0WmBBMYcnqSoAYjc/kcsbWF1YbhvDq1kA6EuYGB0o
3cNQkycosXicMqKgPURmILhuZ4fc53Yty1gIe2dJcfrSM/sCAwEAAaNTMFEwHQYD
VR0OBBYEFCp9viKGGM4+UmvTcd9myvQ/x4w4MB8GA1UdIwQYMBaAFCp9viKGGM4+
UmvTcd9myvQ/x4w4MA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEB
AHaOJ8ssJjLG9z3eGEmqXSpUPRyKLxt7g+SGYziTgRvLmmLxltxFU0SNaHN6a/ax
3T08c1t2T28XK0kqYxEVR7xWAA8Y96GwXB2D12NDOpR96LT1eN33GpjZZLB6NvuI
cgfaDvr/Sl08V2aoamJKyS28FtUvCOELPE7qcwIYw3oL8Rp6uZUpho+SUzgcoNd5
JYUPWyWo4MVj8hDy3Ebo7YjZhkYZPaV1gA0BTOfZWi/0E/Okr/XQkxaaRihc16xF
68fPmPSEy7xRvjDuUOu7WAOxUR+axcLzuZhHIQCSxwyMBG7zXXre6X/AzQnQ14qe
jVPqpsCFhz+xUGJV7WSwfMQ=
-----END CERTIFICATE-----";
}

sub saml_key_sp_cert_sig {
    "-----BEGIN CERTIFICATE-----
MIIDbTCCAlWgAwIBAgIUXDHeTxgAdIpOp2++gWrRaBr9CxwwDQYJKoZIhvcNAQEL
BQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM
GEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDAgFw0yNTA4MDExNDA0NDFaGA8yMTI1
MDcwODE0MDQ0MVowRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUx
ITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBALuIk6GABJlkMYGQ4oRlczDKpdXpT59+3aJlnL13
lNhOMrdoYeY5EB4hY4KHXzpTXkSMOUCVZVAcK/gkL22ikRV3ewazoUCAwtE2T0VQ
dFx2q1LbArg3pDeP9hiksx7KE6ClFT1qvbYbLnpN8ZKbCRmTV+24JXxHPfkEKWE6
jda5HTdT1VNHqTTKJBRRoaOaS0ai1FefiP0FwC+PY3042ksbKeFJ3UyPP/phkkUq
vp609s8kETP75I+b0fWVc+uxzv/lpNzMekQMJFXDHYDAKgqvKHZmyNMgkWYky/cm
ylkSqliaCidKefkNnzxAT7qUGUdPSbfyT7i1UrBnwsYvTasCAwEAAaNTMFEwHQYD
VR0OBBYEFEWmfbeUIDfMp28Nm5ZoYCBww1NnMB8GA1UdIwQYMBaAFEWmfbeUIDfM
p28Nm5ZoYCBww1NnMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEB
ALA5okXVSvdIb0GtYhon2d22X5Hpd16n3UHxFcEfRClz/fR1t42BjJeVsjoB9gdq
ded8X3Wx5Ufmx+IcP5MkItA4X3poctULnScyraL8Bjyiry2mmMwssS7dxfKtq0kb
Cjkt9aKdVg/K4IpjfAL2yWN7dLhyKC8iFQTGZQLEYSoWllU6O0mY1G3yESnd3ZhM
pm6Hj4As5CxdlhRC3wFe0WSsXctXZXnig5Vu8aXvuJdGCmeimLmmVUN6XoKs04km
GpOaw66yU3Q2Bkj0Q32V6eoXHxeMmJzRFjlAlFX8ouaTXIJlla1zQ6EEVhhHyIJx
qkDlp/EbsA5pW9bJpalb0hA=
-----END CERTIFICATE-----";
}

sub samlSPMetaDataXML {
    my ( $name, $type ) = @_;
    my $org = uc($name);
    return <<"EOF"
<?xml version="1.0"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
entityID="http://auth.$name.com/saml/metadata">
  <IDPSSODescriptor WantAuthnRequestsSigned="true"
  protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            u4iToYAEmWQxgZDihGVzMMql1elPn37domWcvXeU2E4yt2hh5jkQHiFjgodfOlNeRIw5QJVlUBwr
            +CQvbaKRFXd7BrOhQIDC0TZPRVB0XHarUtsCuDekN4/2GKSzHsoToKUVPWq9thsuek3xkpsJGZNX
            7bglfEc9+QQpYTqN1rkdN1PVU0epNMokFFGho5pLRqLUV5+I/QXAL49jfTjaSxsp4UndTI8/+mGS
            RSq+nrT2zyQRM/vkj5vR9ZVz67HO/+Wk3Mx6RAwkVcMdgMAqCq8odmbI0yCRZiTL9ybKWRKqWJoK
            J0p5+Q2fPEBPupQZR09Jt/JPuLVSsGfCxi9Nqw==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            sRaod2RZ8hMFBl+VhsnhyPM8l/Fj1obnBxfQIaWuHFIFfXiGe/CYHuZ5QJQLnZxHMJX6LL3Sh+Us
            og3p0jpijpcg0QgfBSEkfopKTgReYN8DiDIll0rV1XdTni7E85Nd1YyNy3ui/ZD+UShWwqu6jLVL
            R+QUm+/1LIKYb3OCBTvOlY7xHoP6NSU1+Mr+YzGBUacdO2vnNxe/PQhxIeP1zO0njuqGHkwEpy8r
            UWRZbbDn31TmKjqlhgtsz5HPhbRaYEExhyepKgBiNz+RyxtYXVhuG8OrWQDoS5gYHSjdw1CTJyix
            eJwyoqA9RGYguG5nh9zndi3LWAh7Z0lx+tIz+w==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <ArtifactResolutionService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/artifact" />
    <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$type"
     Location="http://auth.$name.com/saml/singleLogout"
    ResponseLocation="http://auth.$name.com/saml/singleLogoutReturn" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$type"
     Location="http://auth.$name.com/saml/singleSignOn" />
  </IDPSSODescriptor>
  <SPSSODescriptor AuthnRequestsSigned="true"
  WantAssertionsSigned="true"
  protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            u4iToYAEmWQxgZDihGVzMMql1elPn37domWcvXeU2E4yt2hh5jkQHiFjgodfOlNeRIw5QJVlUBwr
            +CQvbaKRFXd7BrOhQIDC0TZPRVB0XHarUtsCuDekN4/2GKSzHsoToKUVPWq9thsuek3xkpsJGZNX
            7bglfEc9+QQpYTqN1rkdN1PVU0epNMokFFGho5pLRqLUV5+I/QXAL49jfTjaSxsp4UndTI8/+mGS
            RSq+nrT2zyQRM/vkj5vR9ZVz67HO/+Wk3Mx6RAwkVcMdgMAqCq8odmbI0yCRZiTL9ybKWRKqWJoK
            J0p5+Q2fPEBPupQZR09Jt/JPuLVSsGfCxi9Nqw==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            sRaod2RZ8hMFBl+VhsnhyPM8l/Fj1obnBxfQIaWuHFIFfXiGe/CYHuZ5QJQLnZxHMJX6LL3Sh+Us
            og3p0jpijpcg0QgfBSEkfopKTgReYN8DiDIll0rV1XdTni7E85Nd1YyNy3ui/ZD+UShWwqu6jLVL
            R+QUm+/1LIKYb3OCBTvOlY7xHoP6NSU1+Mr+YzGBUacdO2vnNxe/PQhxIeP1zO0njuqGHkwEpy8r
            UWRZbbDn31TmKjqlhgtsz5HPhbRaYEExhyepKgBiNz+RyxtYXVhuG8OrWQDoS5gYHSjdw1CTJyix
            eJwyoqA9RGYguG5nh9zndi3LWAh7Z0lx+tIz+w==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <ArtifactResolutionService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/artifact" />
    <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$type"
     Location="http://auth.$name.com/saml/proxySingleLogout"
    ResponseLocation="http://auth.$name.com/saml/proxySingleLogoutReturn" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <AssertionConsumerService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
     Location="http://auth.$name.com/saml/proxySingleSignOnPost" />
    <AssertionConsumerService isDefault="false" index="1"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact"
     Location="http://auth.$name.com/saml/proxySingleSignOnArtifact" />
    <AssertionConsumerService isDefault="true" index="2"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
     Location="http://auth.alternate.com/saml/proxySingleSignOnPost" />
  </SPSSODescriptor>
  <AttributeAuthorityDescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            u4iToYAEmWQxgZDihGVzMMql1elPn37domWcvXeU2E4yt2hh5jkQHiFjgodfOlNeRIw5QJVlUBwr
            +CQvbaKRFXd7BrOhQIDC0TZPRVB0XHarUtsCuDekN4/2GKSzHsoToKUVPWq9thsuek3xkpsJGZNX
            7bglfEc9+QQpYTqN1rkdN1PVU0epNMokFFGho5pLRqLUV5+I/QXAL49jfTjaSxsp4UndTI8/+mGS
            RSq+nrT2zyQRM/vkj5vR9ZVz67HO/+Wk3Mx6RAwkVcMdgMAqCq8odmbI0yCRZiTL9ybKWRKqWJoK
            J0p5+Q2fPEBPupQZR09Jt/JPuLVSsGfCxi9Nqw==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            sRaod2RZ8hMFBl+VhsnhyPM8l/Fj1obnBxfQIaWuHFIFfXiGe/CYHuZ5QJQLnZxHMJX6LL3Sh+Us
            og3p0jpijpcg0QgfBSEkfopKTgReYN8DiDIll0rV1XdTni7E85Nd1YyNy3ui/ZD+UShWwqu6jLVL
            R+QUm+/1LIKYb3OCBTvOlY7xHoP6NSU1+Mr+YzGBUacdO2vnNxe/PQhxIeP1zO0njuqGHkwEpy8r
            UWRZbbDn31TmKjqlhgtsz5HPhbRaYEExhyepKgBiNz+RyxtYXVhuG8OrWQDoS5gYHSjdw1CTJyix
            eJwyoqA9RGYguG5nh9zndi3LWAh7Z0lx+tIz+w==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <AttributeService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/AA/SOAP" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
  </AttributeAuthorityDescriptor>
  <Organization>
    <OrganizationName xml:lang="en">$org</OrganizationName>
    <OrganizationDisplayName xml:lang="en">
    $org</OrganizationDisplayName>
    <OrganizationURL xml:lang="en">
    http://www.$name.com</OrganizationURL>
  </Organization>
</EntityDescriptor>
EOF
      ;
}

sub samlSPComplexMetaDataXML {
    my ( $name, $typeSSO, $typeSLO ) = @_;
    my $org = uc($name);
    return <<"EOF"
<?xml version="1.0"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
entityID="http://auth.$name.com/saml/metadata">
  <IDPSSODescriptor WantAuthnRequestsSigned="true"
  protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            u4iToYAEmWQxgZDihGVzMMql1elPn37domWcvXeU2E4yt2hh5jkQHiFjgodfOlNeRIw5QJVlUBwr
            +CQvbaKRFXd7BrOhQIDC0TZPRVB0XHarUtsCuDekN4/2GKSzHsoToKUVPWq9thsuek3xkpsJGZNX
            7bglfEc9+QQpYTqN1rkdN1PVU0epNMokFFGho5pLRqLUV5+I/QXAL49jfTjaSxsp4UndTI8/+mGS
            RSq+nrT2zyQRM/vkj5vR9ZVz67HO/+Wk3Mx6RAwkVcMdgMAqCq8odmbI0yCRZiTL9ybKWRKqWJoK
            J0p5+Q2fPEBPupQZR09Jt/JPuLVSsGfCxi9Nqw==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            sRaod2RZ8hMFBl+VhsnhyPM8l/Fj1obnBxfQIaWuHFIFfXiGe/CYHuZ5QJQLnZxHMJX6LL3Sh+Us
            og3p0jpijpcg0QgfBSEkfopKTgReYN8DiDIll0rV1XdTni7E85Nd1YyNy3ui/ZD+UShWwqu6jLVL
            R+QUm+/1LIKYb3OCBTvOlY7xHoP6NSU1+Mr+YzGBUacdO2vnNxe/PQhxIeP1zO0njuqGHkwEpy8r
            UWRZbbDn31TmKjqlhgtsz5HPhbRaYEExhyepKgBiNz+RyxtYXVhuG8OrWQDoS5gYHSjdw1CTJyix
            eJwyoqA9RGYguG5nh9zndi3LWAh7Z0lx+tIz+w==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <ArtifactResolutionService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/artifact" />
    <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$typeSLO"
     Location="http://auth.$name.com/saml/singleLogout"
    ResponseLocation="http://auth.$name.com/saml/singleLogoutReturn" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$typeSSO"
     Location="http://auth.$name.com/saml/singleSignOn" />
  </IDPSSODescriptor>
  <SPSSODescriptor AuthnRequestsSigned="true"
  WantAssertionsSigned="true"
  protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            u4iToYAEmWQxgZDihGVzMMql1elPn37domWcvXeU2E4yt2hh5jkQHiFjgodfOlNeRIw5QJVlUBwr
            +CQvbaKRFXd7BrOhQIDC0TZPRVB0XHarUtsCuDekN4/2GKSzHsoToKUVPWq9thsuek3xkpsJGZNX
            7bglfEc9+QQpYTqN1rkdN1PVU0epNMokFFGho5pLRqLUV5+I/QXAL49jfTjaSxsp4UndTI8/+mGS
            RSq+nrT2zyQRM/vkj5vR9ZVz67HO/+Wk3Mx6RAwkVcMdgMAqCq8odmbI0yCRZiTL9ybKWRKqWJoK
            J0p5+Q2fPEBPupQZR09Jt/JPuLVSsGfCxi9Nqw==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            sRaod2RZ8hMFBl+VhsnhyPM8l/Fj1obnBxfQIaWuHFIFfXiGe/CYHuZ5QJQLnZxHMJX6LL3Sh+Us
            og3p0jpijpcg0QgfBSEkfopKTgReYN8DiDIll0rV1XdTni7E85Nd1YyNy3ui/ZD+UShWwqu6jLVL
            R+QUm+/1LIKYb3OCBTvOlY7xHoP6NSU1+Mr+YzGBUacdO2vnNxe/PQhxIeP1zO0njuqGHkwEpy8r
            UWRZbbDn31TmKjqlhgtsz5HPhbRaYEExhyepKgBiNz+RyxtYXVhuG8OrWQDoS5gYHSjdw1CTJyix
            eJwyoqA9RGYguG5nh9zndi3LWAh7Z0lx+tIz+w==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <ArtifactResolutionService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/artifact" />
    <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$typeSLO"
     Location="http://auth.$name.com/saml/proxySingleLogout"
    ResponseLocation="http://auth.$name.com/saml/proxySingleLogoutReturn" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <AssertionConsumerService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
     Location="http://auth.$name.com/saml/proxySingleSignOnPost" />
    <AssertionConsumerService isDefault="false" index="1"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact"
     Location="http://auth.$name.com/saml/proxySingleSignOnArtifact" />
    <AssertionConsumerService isDefault="true" index="2"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
     Location="http://auth.alternate.com/saml/proxySingleSignOnPost" />
  </SPSSODescriptor>
  <AttributeAuthorityDescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            u4iToYAEmWQxgZDihGVzMMql1elPn37domWcvXeU2E4yt2hh5jkQHiFjgodfOlNeRIw5QJVlUBwr
            +CQvbaKRFXd7BrOhQIDC0TZPRVB0XHarUtsCuDekN4/2GKSzHsoToKUVPWq9thsuek3xkpsJGZNX
            7bglfEc9+QQpYTqN1rkdN1PVU0epNMokFFGho5pLRqLUV5+I/QXAL49jfTjaSxsp4UndTI8/+mGS
            RSq+nrT2zyQRM/vkj5vR9ZVz67HO/+Wk3Mx6RAwkVcMdgMAqCq8odmbI0yCRZiTL9ybKWRKqWJoK
            J0p5+Q2fPEBPupQZR09Jt/JPuLVSsGfCxi9Nqw==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            sRaod2RZ8hMFBl+VhsnhyPM8l/Fj1obnBxfQIaWuHFIFfXiGe/CYHuZ5QJQLnZxHMJX6LL3Sh+Us
            og3p0jpijpcg0QgfBSEkfopKTgReYN8DiDIll0rV1XdTni7E85Nd1YyNy3ui/ZD+UShWwqu6jLVL
            R+QUm+/1LIKYb3OCBTvOlY7xHoP6NSU1+Mr+YzGBUacdO2vnNxe/PQhxIeP1zO0njuqGHkwEpy8r
            UWRZbbDn31TmKjqlhgtsz5HPhbRaYEExhyepKgBiNz+RyxtYXVhuG8OrWQDoS5gYHSjdw1CTJyix
            eJwyoqA9RGYguG5nh9zndi3LWAh7Z0lx+tIz+w==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <AttributeService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/AA/SOAP" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
  </AttributeAuthorityDescriptor>
  <Organization>
    <OrganizationName xml:lang="en">$org</OrganizationName>
    <OrganizationDisplayName xml:lang="en">
    $org</OrganizationDisplayName>
    <OrganizationURL xml:lang="en">
    http://www.$name.com</OrganizationURL>
  </Organization>
</EntityDescriptor>
EOF
      ;
}

sub samlProxyMetaDataXML {
    my ( $name, $type ) = @_;
    my $org = uc($name);
    return <<"EOF"
<?xml version="1.0"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
entityID="http://auth.$name.com/saml/metadata">
  <IDPSSODescriptor WantAuthnRequestsSigned="true"
  protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <ds:KeyValue>
	<RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
		<Modulus>ztmb1JZk/agkYYm23D4dqaLS4EKHKrjO4eBvwtWZLexAGR1KDpcrHqLyqJoal+q4A8drI7lxElSt
6xRKJ4DIxQM1jqRcmE6EzdL6BfTaRace3zIuhjDSQUZJdtFtlJynQT1cJbx5ZYhqZbYANm9NZRcY
Z5gWeyF9nl41xA79AMuYlpt7eWDR8cnQJXwV790991FQ9yA2BBgTdSKkFqZ72P4lWu4shz3JCGf5
hyq03hCHQ7bsfpgAdCrbQPTuJNFtS599ClMu+AcRcwJcS233pHd306PRHCXn3Eapq6gEoHxgLVNp
+luAIhRA9EaOnZ0nVkFwFKn3vLXzV01iTliMeQ==
</Modulus>
		<Exponent>AQAB
</Exponent>
	</RSAKeyValue>
</ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <ds:KeyValue>
	<RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
		<Modulus>2vzoUiQ4GsM5qLjoxslEDKj+RrPh/A743JCWe1Hbadjd5yD4gPwmJUxMF+MJcQlo/TkmKbTonPdI
oAqDknbUxfFTntp0VkdKrB64xr0Stpy7123hPszat3SbU3RYypdobEcuSAS77w9X1KnkRL1+CIe5
9qSsghO3l3b2IJ6qPFXdx/cro7+K3O7w8wAEJ9KmxA0KdiZpSFgTAqfNDSKx8NLwZOeDpsHouAxy
1E2kine+9ESBTRAM2PgiGZvU5JA1SZscdEg3wTftJxxPFnAJMwtqM3IVC6B+TqsIP5Wlk1PQQqH7
5gjtBYDVduynBwU+l/UUmp1aDRZupuH8PF51pw==
</Modulus>
		<Exponent>AQAB
</Exponent>
	</RSAKeyValue>
</ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <ArtifactResolutionService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/artifact" />
    <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$type"
     Location="http://auth.$name.com/saml/singleLogout"
    ResponseLocation="http://auth.$name.com/saml/singleLogoutReturn" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$type"
     Location="http://auth.$name.com/saml/singleSignOn" />
  </IDPSSODescriptor>
  <SPSSODescriptor AuthnRequestsSigned="true"
  WantAssertionsSigned="true"
  protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <ds:KeyValue>
	<RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
		<Modulus>ztmb1JZk/agkYYm23D4dqaLS4EKHKrjO4eBvwtWZLexAGR1KDpcrHqLyqJoal+q4A8drI7lxElSt
6xRKJ4DIxQM1jqRcmE6EzdL6BfTaRace3zIuhjDSQUZJdtFtlJynQT1cJbx5ZYhqZbYANm9NZRcY
Z5gWeyF9nl41xA79AMuYlpt7eWDR8cnQJXwV790991FQ9yA2BBgTdSKkFqZ72P4lWu4shz3JCGf5
hyq03hCHQ7bsfpgAdCrbQPTuJNFtS599ClMu+AcRcwJcS233pHd306PRHCXn3Eapq6gEoHxgLVNp
+luAIhRA9EaOnZ0nVkFwFKn3vLXzV01iTliMeQ==
</Modulus>
		<Exponent>AQAB
</Exponent>
	</RSAKeyValue>
</ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <ds:KeyValue>
	<RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
		<Modulus>2vzoUiQ4GsM5qLjoxslEDKj+RrPh/A743JCWe1Hbadjd5yD4gPwmJUxMF+MJcQlo/TkmKbTonPdI
oAqDknbUxfFTntp0VkdKrB64xr0Stpy7123hPszat3SbU3RYypdobEcuSAS77w9X1KnkRL1+CIe5
9qSsghO3l3b2IJ6qPFXdx/cro7+K3O7w8wAEJ9KmxA0KdiZpSFgTAqfNDSKx8NLwZOeDpsHouAxy
1E2kine+9ESBTRAM2PgiGZvU5JA1SZscdEg3wTftJxxPFnAJMwtqM3IVC6B+TqsIP5Wlk1PQQqH7
5gjtBYDVduynBwU+l/UUmp1aDRZupuH8PF51pw==
</Modulus>
		<Exponent>AQAB
</Exponent>
	</RSAKeyValue>
</ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <ArtifactResolutionService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/artifact" />
    <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$type"
     Location="http://auth.$name.com/saml/proxySingleLogout"
    ResponseLocation="http://auth.$name.com/saml/proxySingleLogoutReturn" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <AssertionConsumerService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
     Location="http://auth.$name.com/saml/proxySingleSignOnPost" />
    <AssertionConsumerService isDefault="false" index="1"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact"
     Location="http://auth.$name.com/saml/proxySingleSignOnArtifact" />
  </SPSSODescriptor>
  <AttributeAuthorityDescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <ds:KeyValue>
	<RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
		<Modulus>ztmb1JZk/agkYYm23D4dqaLS4EKHKrjO4eBvwtWZLexAGR1KDpcrHqLyqJoal+q4A8drI7lxElSt
6xRKJ4DIxQM1jqRcmE6EzdL6BfTaRace3zIuhjDSQUZJdtFtlJynQT1cJbx5ZYhqZbYANm9NZRcY
Z5gWeyF9nl41xA79AMuYlpt7eWDR8cnQJXwV790991FQ9yA2BBgTdSKkFqZ72P4lWu4shz3JCGf5
hyq03hCHQ7bsfpgAdCrbQPTuJNFtS599ClMu+AcRcwJcS233pHd306PRHCXn3Eapq6gEoHxgLVNp
+luAIhRA9EaOnZ0nVkFwFKn3vLXzV01iTliMeQ==
</Modulus>
		<Exponent>AQAB
</Exponent>
	</RSAKeyValue>
</ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <ds:KeyValue>
	<RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
		<Modulus>2vzoUiQ4GsM5qLjoxslEDKj+RrPh/A743JCWe1Hbadjd5yD4gPwmJUxMF+MJcQlo/TkmKbTonPdI
oAqDknbUxfFTntp0VkdKrB64xr0Stpy7123hPszat3SbU3RYypdobEcuSAS77w9X1KnkRL1+CIe5
9qSsghO3l3b2IJ6qPFXdx/cro7+K3O7w8wAEJ9KmxA0KdiZpSFgTAqfNDSKx8NLwZOeDpsHouAxy
1E2kine+9ESBTRAM2PgiGZvU5JA1SZscdEg3wTftJxxPFnAJMwtqM3IVC6B+TqsIP5Wlk1PQQqH7
5gjtBYDVduynBwU+l/UUmp1aDRZupuH8PF51pw==
</Modulus>
		<Exponent>AQAB
</Exponent>
	</RSAKeyValue>
</ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <AttributeService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/AA/SOAP" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
  </AttributeAuthorityDescriptor>
  <Organization>
    <OrganizationName xml:lang="en">$org</OrganizationName>
    <OrganizationDisplayName xml:lang="en">
    $org</OrganizationDisplayName>
    <OrganizationURL xml:lang="en">
    http://www.$name.com</OrganizationURL>
  </Organization>
</EntityDescriptor>
EOF
      ;
}

sub samlProxyComplexMetaDataXML {
    my ( $name, $typeSSO, $typeSLO ) = @_;
    my $org = uc($name);
    return <<"EOF"
<?xml version="1.0"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
entityID="http://auth.$name.com/saml/metadata">
  <IDPSSODescriptor WantAuthnRequestsSigned="true"
  protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <ds:KeyValue>
	<RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
		<Modulus>ztmb1JZk/agkYYm23D4dqaLS4EKHKrjO4eBvwtWZLexAGR1KDpcrHqLyqJoal+q4A8drI7lxElSt
6xRKJ4DIxQM1jqRcmE6EzdL6BfTaRace3zIuhjDSQUZJdtFtlJynQT1cJbx5ZYhqZbYANm9NZRcY
Z5gWeyF9nl41xA79AMuYlpt7eWDR8cnQJXwV790991FQ9yA2BBgTdSKkFqZ72P4lWu4shz3JCGf5
hyq03hCHQ7bsfpgAdCrbQPTuJNFtS599ClMu+AcRcwJcS233pHd306PRHCXn3Eapq6gEoHxgLVNp
+luAIhRA9EaOnZ0nVkFwFKn3vLXzV01iTliMeQ==
</Modulus>
		<Exponent>AQAB
</Exponent>
	</RSAKeyValue>
</ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <ds:KeyValue>
	<RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
		<Modulus>2vzoUiQ4GsM5qLjoxslEDKj+RrPh/A743JCWe1Hbadjd5yD4gPwmJUxMF+MJcQlo/TkmKbTonPdI
oAqDknbUxfFTntp0VkdKrB64xr0Stpy7123hPszat3SbU3RYypdobEcuSAS77w9X1KnkRL1+CIe5
9qSsghO3l3b2IJ6qPFXdx/cro7+K3O7w8wAEJ9KmxA0KdiZpSFgTAqfNDSKx8NLwZOeDpsHouAxy
1E2kine+9ESBTRAM2PgiGZvU5JA1SZscdEg3wTftJxxPFnAJMwtqM3IVC6B+TqsIP5Wlk1PQQqH7
5gjtBYDVduynBwU+l/UUmp1aDRZupuH8PF51pw==
</Modulus>
		<Exponent>AQAB
</Exponent>
	</RSAKeyValue>
</ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <ArtifactResolutionService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/artifact" />
    <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$typeSLO"
     Location="http://auth.$name.com/saml/singleLogout"
    ResponseLocation="http://auth.$name.com/saml/singleLogoutReturn" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$typeSSO"
     Location="http://auth.$name.com/saml/singleSignOn" />
  </IDPSSODescriptor>
  <SPSSODescriptor AuthnRequestsSigned="true"
  WantAssertionsSigned="true"
  protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <ds:KeyValue>
	<RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
		<Modulus>ztmb1JZk/agkYYm23D4dqaLS4EKHKrjO4eBvwtWZLexAGR1KDpcrHqLyqJoal+q4A8drI7lxElSt
6xRKJ4DIxQM1jqRcmE6EzdL6BfTaRace3zIuhjDSQUZJdtFtlJynQT1cJbx5ZYhqZbYANm9NZRcY
Z5gWeyF9nl41xA79AMuYlpt7eWDR8cnQJXwV790991FQ9yA2BBgTdSKkFqZ72P4lWu4shz3JCGf5
hyq03hCHQ7bsfpgAdCrbQPTuJNFtS599ClMu+AcRcwJcS233pHd306PRHCXn3Eapq6gEoHxgLVNp
+luAIhRA9EaOnZ0nVkFwFKn3vLXzV01iTliMeQ==
</Modulus>
		<Exponent>AQAB
</Exponent>
	</RSAKeyValue>
</ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <ds:KeyValue>
	<RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
		<Modulus>2vzoUiQ4GsM5qLjoxslEDKj+RrPh/A743JCWe1Hbadjd5yD4gPwmJUxMF+MJcQlo/TkmKbTonPdI
oAqDknbUxfFTntp0VkdKrB64xr0Stpy7123hPszat3SbU3RYypdobEcuSAS77w9X1KnkRL1+CIe5
9qSsghO3l3b2IJ6qPFXdx/cro7+K3O7w8wAEJ9KmxA0KdiZpSFgTAqfNDSKx8NLwZOeDpsHouAxy
1E2kine+9ESBTRAM2PgiGZvU5JA1SZscdEg3wTftJxxPFnAJMwtqM3IVC6B+TqsIP5Wlk1PQQqH7
5gjtBYDVduynBwU+l/UUmp1aDRZupuH8PF51pw==
</Modulus>
		<Exponent>AQAB
</Exponent>
	</RSAKeyValue>
</ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <ArtifactResolutionService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/artifact" />
    <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$typeSLO"
     Location="http://auth.$name.com/saml/proxySingleLogout"
    ResponseLocation="http://auth.$name.com/saml/proxySingleLogoutReturn" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <AssertionConsumerService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
     Location="http://auth.$name.com/saml/proxySingleSignOnPost" />
    <AssertionConsumerService isDefault="false" index="1"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact"
     Location="http://auth.$name.com/saml/proxySingleSignOnArtifact" />
  </SPSSODescriptor>
  <AttributeAuthorityDescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <ds:KeyValue>
	<RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
		<Modulus>ztmb1JZk/agkYYm23D4dqaLS4EKHKrjO4eBvwtWZLexAGR1KDpcrHqLyqJoal+q4A8drI7lxElSt
6xRKJ4DIxQM1jqRcmE6EzdL6BfTaRace3zIuhjDSQUZJdtFtlJynQT1cJbx5ZYhqZbYANm9NZRcY
Z5gWeyF9nl41xA79AMuYlpt7eWDR8cnQJXwV790991FQ9yA2BBgTdSKkFqZ72P4lWu4shz3JCGf5
hyq03hCHQ7bsfpgAdCrbQPTuJNFtS599ClMu+AcRcwJcS233pHd306PRHCXn3Eapq6gEoHxgLVNp
+luAIhRA9EaOnZ0nVkFwFKn3vLXzV01iTliMeQ==
</Modulus>
		<Exponent>AQAB
</Exponent>
	</RSAKeyValue>
</ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
          <ds:KeyValue>
	<RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
		<Modulus>2vzoUiQ4GsM5qLjoxslEDKj+RrPh/A743JCWe1Hbadjd5yD4gPwmJUxMF+MJcQlo/TkmKbTonPdI
oAqDknbUxfFTntp0VkdKrB64xr0Stpy7123hPszat3SbU3RYypdobEcuSAS77w9X1KnkRL1+CIe5
9qSsghO3l3b2IJ6qPFXdx/cro7+K3O7w8wAEJ9KmxA0KdiZpSFgTAqfNDSKx8NLwZOeDpsHouAxy
1E2kine+9ESBTRAM2PgiGZvU5JA1SZscdEg3wTftJxxPFnAJMwtqM3IVC6B+TqsIP5Wlk1PQQqH7
5gjtBYDVduynBwU+l/UUmp1aDRZupuH8PF51pw==
</Modulus>
		<Exponent>AQAB
</Exponent>
	</RSAKeyValue>
</ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <AttributeService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/AA/SOAP" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
  </AttributeAuthorityDescriptor>
  <Organization>
    <OrganizationName xml:lang="en">$org</OrganizationName>
    <OrganizationDisplayName xml:lang="en">
    $org</OrganizationDisplayName>
    <OrganizationURL xml:lang="en">
    http://www.$name.com</OrganizationURL>
  </Organization>
</EntityDescriptor>
EOF
      ;
}

sub samlIDPMetaDataXML {
    my ( $name, $type ) = @_;
    my $org = uc($name);
    return <<"EOF"
<?xml version="1.0"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
entityID="http://auth.$name.com/saml/metadata">
  <IDPSSODescriptor WantAuthnRequestsSigned="true"
  protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            tR/wgDqWB4Maho5V6TjcL/NbNfjgIh7GcgkrB5RZcVT1GTejJlMjUQdgBKBuZXQN+7/29P6UcGq1
            kYalURq6S8SpeJ1ofp5rBEoD/TIkvU0JOcid65wp+fdzXGXsfiZvHraU74jSCgjP/wqfVGRyBIQz
            B0SIxSpnrsigqNsE1E94toDMx4wovjHu/9ABAImREV7Sz83OeFF00/sghrjTEJOD/gHf04JCn9Mg
            NOqvSTysr9LXWg/oUKQDEYeTq9ux6pq/oqv1MxwONbSZPtN5yD41mi+hT8Rh+W8Je8rsiML4VMxz
            sb1l9303asw6suo5bLTISKNSbu1nt1NkpNxzyw==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            nfKBDG/K0TnGT7Xu8q1N45sNWvIK91SqNg8nvN2uVeKoHADTcsus5Xn3id5+8Q9TuMFsW9kIEeXi
            aPKXQa9ryfSNDhWDWloNkpGEeWif2BnHUu46Abu1UBWb0mH6VwcG1PR4qHruLis1odjQ1qnVDNfS
            EASVIppEBYjDX203ypmURIzU6h53GRRRlf1BLWkbVn9ysmDeR57Xw5Rsx/+tBlcnMrkv/40DSUke
            hQIl2JmlFrl2Caik+gU4pd20apA/pNLjBZF0OmGoS08AIR5NMd0KFa6CwZUUSHJqH5GFy5Y2yl4l
            g8K0klAS9q7L7aXI+eFQZhkwidjpxXnHPyxIGQ==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <ArtifactResolutionService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/artifact" />
    <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$type"
     Location="http://auth.$name.com/saml/singleLogout"
    ResponseLocation="http://auth.$name.com/saml/singleLogoutReturn" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$type"
     Location="http://auth.$name.com/saml/singleSignOn" />
  </IDPSSODescriptor>
  <SPSSODescriptor AuthnRequestsSigned="true"
  WantAssertionsSigned="true"
  protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            tR/wgDqWB4Maho5V6TjcL/NbNfjgIh7GcgkrB5RZcVT1GTejJlMjUQdgBKBuZXQN+7/29P6UcGq1
            kYalURq6S8SpeJ1ofp5rBEoD/TIkvU0JOcid65wp+fdzXGXsfiZvHraU74jSCgjP/wqfVGRyBIQz
            B0SIxSpnrsigqNsE1E94toDMx4wovjHu/9ABAImREV7Sz83OeFF00/sghrjTEJOD/gHf04JCn9Mg
            NOqvSTysr9LXWg/oUKQDEYeTq9ux6pq/oqv1MxwONbSZPtN5yD41mi+hT8Rh+W8Je8rsiML4VMxz
            sb1l9303asw6suo5bLTISKNSbu1nt1NkpNxzyw==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            nfKBDG/K0TnGT7Xu8q1N45sNWvIK91SqNg8nvN2uVeKoHADTcsus5Xn3id5+8Q9TuMFsW9kIEeXi
            aPKXQa9ryfSNDhWDWloNkpGEeWif2BnHUu46Abu1UBWb0mH6VwcG1PR4qHruLis1odjQ1qnVDNfS
            EASVIppEBYjDX203ypmURIzU6h53GRRRlf1BLWkbVn9ysmDeR57Xw5Rsx/+tBlcnMrkv/40DSUke
            hQIl2JmlFrl2Caik+gU4pd20apA/pNLjBZF0OmGoS08AIR5NMd0KFa6CwZUUSHJqH5GFy5Y2yl4l
            g8K0klAS9q7L7aXI+eFQZhkwidjpxXnHPyxIGQ==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <ArtifactResolutionService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/artifact" />
    <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$type"
     Location="http://auth.$name.com/saml/proxySingleLogout"
    ResponseLocation="http://auth.$name.com/saml/proxySingleLogoutReturn" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <AssertionConsumerService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
     Location="http://auth.$name.com/saml/proxySingleSignOnPost" />
    <AssertionConsumerService isDefault="false" index="1"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact"
     Location="http://auth.$name.com/saml/proxySingleSignOnArtifact" />
  </SPSSODescriptor>
  <AttributeAuthorityDescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            tR/wgDqWB4Maho5V6TjcL/NbNfjgIh7GcgkrB5RZcVT1GTejJlMjUQdgBKBuZXQN+7/29P6UcGq1
            kYalURq6S8SpeJ1ofp5rBEoD/TIkvU0JOcid65wp+fdzXGXsfiZvHraU74jSCgjP/wqfVGRyBIQz
            B0SIxSpnrsigqNsE1E94toDMx4wovjHu/9ABAImREV7Sz83OeFF00/sghrjTEJOD/gHf04JCn9Mg
            NOqvSTysr9LXWg/oUKQDEYeTq9ux6pq/oqv1MxwONbSZPtN5yD41mi+hT8Rh+W8Je8rsiML4VMxz
            sb1l9303asw6suo5bLTISKNSbu1nt1NkpNxzyw==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            nfKBDG/K0TnGT7Xu8q1N45sNWvIK91SqNg8nvN2uVeKoHADTcsus5Xn3id5+8Q9TuMFsW9kIEeXi
            aPKXQa9ryfSNDhWDWloNkpGEeWif2BnHUu46Abu1UBWb0mH6VwcG1PR4qHruLis1odjQ1qnVDNfS
            EASVIppEBYjDX203ypmURIzU6h53GRRRlf1BLWkbVn9ysmDeR57Xw5Rsx/+tBlcnMrkv/40DSUke
            hQIl2JmlFrl2Caik+gU4pd20apA/pNLjBZF0OmGoS08AIR5NMd0KFa6CwZUUSHJqH5GFy5Y2yl4l
            g8K0klAS9q7L7aXI+eFQZhkwidjpxXnHPyxIGQ==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <AttributeService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/AA/SOAP" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
  </AttributeAuthorityDescriptor>
  <Organization>
    <OrganizationName xml:lang="en">$org</OrganizationName>
    <OrganizationDisplayName xml:lang="en">
    $org</OrganizationDisplayName>
    <OrganizationURL xml:lang="en">
    http://www.$name.fr/</OrganizationURL>
  </Organization>
</EntityDescriptor>
EOF
      ;
}

sub samlIDPComplexMetaDataXML {
    my ( $name, $typeSSO, $typeSLO ) = @_;
    my $org = uc($name);
    return <<"EOF"
<?xml version="1.0"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
entityID="http://auth.$name.com/saml/metadata">
  <IDPSSODescriptor WantAuthnRequestsSigned="true"
  protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            tR/wgDqWB4Maho5V6TjcL/NbNfjgIh7GcgkrB5RZcVT1GTejJlMjUQdgBKBuZXQN+7/29P6UcGq1
            kYalURq6S8SpeJ1ofp5rBEoD/TIkvU0JOcid65wp+fdzXGXsfiZvHraU74jSCgjP/wqfVGRyBIQz
            B0SIxSpnrsigqNsE1E94toDMx4wovjHu/9ABAImREV7Sz83OeFF00/sghrjTEJOD/gHf04JCn9Mg
            NOqvSTysr9LXWg/oUKQDEYeTq9ux6pq/oqv1MxwONbSZPtN5yD41mi+hT8Rh+W8Je8rsiML4VMxz
            sb1l9303asw6suo5bLTISKNSbu1nt1NkpNxzyw==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            nfKBDG/K0TnGT7Xu8q1N45sNWvIK91SqNg8nvN2uVeKoHADTcsus5Xn3id5+8Q9TuMFsW9kIEeXi
            aPKXQa9ryfSNDhWDWloNkpGEeWif2BnHUu46Abu1UBWb0mH6VwcG1PR4qHruLis1odjQ1qnVDNfS
            EASVIppEBYjDX203ypmURIzU6h53GRRRlf1BLWkbVn9ysmDeR57Xw5Rsx/+tBlcnMrkv/40DSUke
            hQIl2JmlFrl2Caik+gU4pd20apA/pNLjBZF0OmGoS08AIR5NMd0KFa6CwZUUSHJqH5GFy5Y2yl4l
            g8K0klAS9q7L7aXI+eFQZhkwidjpxXnHPyxIGQ==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <ArtifactResolutionService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/artifact" />
    <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$typeSLO"
     Location="http://auth.$name.com/saml/singleLogout"
    ResponseLocation="http://auth.$name.com/saml/singleLogoutReturn" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$typeSSO"
     Location="http://auth.$name.com/saml/singleSignOn" />
  </IDPSSODescriptor>
  <SPSSODescriptor AuthnRequestsSigned="true"
  WantAssertionsSigned="true"
  protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            tR/wgDqWB4Maho5V6TjcL/NbNfjgIh7GcgkrB5RZcVT1GTejJlMjUQdgBKBuZXQN+7/29P6UcGq1
            kYalURq6S8SpeJ1ofp5rBEoD/TIkvU0JOcid65wp+fdzXGXsfiZvHraU74jSCgjP/wqfVGRyBIQz
            B0SIxSpnrsigqNsE1E94toDMx4wovjHu/9ABAImREV7Sz83OeFF00/sghrjTEJOD/gHf04JCn9Mg
            NOqvSTysr9LXWg/oUKQDEYeTq9ux6pq/oqv1MxwONbSZPtN5yD41mi+hT8Rh+W8Je8rsiML4VMxz
            sb1l9303asw6suo5bLTISKNSbu1nt1NkpNxzyw==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            nfKBDG/K0TnGT7Xu8q1N45sNWvIK91SqNg8nvN2uVeKoHADTcsus5Xn3id5+8Q9TuMFsW9kIEeXi
            aPKXQa9ryfSNDhWDWloNkpGEeWif2BnHUu46Abu1UBWb0mH6VwcG1PR4qHruLis1odjQ1qnVDNfS
            EASVIppEBYjDX203ypmURIzU6h53GRRRlf1BLWkbVn9ysmDeR57Xw5Rsx/+tBlcnMrkv/40DSUke
            hQIl2JmlFrl2Caik+gU4pd20apA/pNLjBZF0OmGoS08AIR5NMd0KFa6CwZUUSHJqH5GFy5Y2yl4l
            g8K0klAS9q7L7aXI+eFQZhkwidjpxXnHPyxIGQ==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <ArtifactResolutionService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/artifact" />
    <SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:$typeSLO"
     Location="http://auth.$name.com/saml/proxySingleLogout"
    ResponseLocation="http://auth.$name.com/saml/proxySingleLogoutReturn" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <AssertionConsumerService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
     Location="http://auth.$name.com/saml/proxySingleSignOnPost" />
    <AssertionConsumerService isDefault="false" index="1"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact"
     Location="http://auth.$name.com/saml/proxySingleSignOnArtifact" />
  </SPSSODescriptor>
  <AttributeAuthorityDescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            tR/wgDqWB4Maho5V6TjcL/NbNfjgIh7GcgkrB5RZcVT1GTejJlMjUQdgBKBuZXQN+7/29P6UcGq1
            kYalURq6S8SpeJ1ofp5rBEoD/TIkvU0JOcid65wp+fdzXGXsfiZvHraU74jSCgjP/wqfVGRyBIQz
            B0SIxSpnrsigqNsE1E94toDMx4wovjHu/9ABAImREV7Sz83OeFF00/sghrjTEJOD/gHf04JCn9Mg
            NOqvSTysr9LXWg/oUKQDEYeTq9ux6pq/oqv1MxwONbSZPtN5yD41mi+hT8Rh+W8Je8rsiML4VMxz
            sb1l9303asw6suo5bLTISKNSbu1nt1NkpNxzyw==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            nfKBDG/K0TnGT7Xu8q1N45sNWvIK91SqNg8nvN2uVeKoHADTcsus5Xn3id5+8Q9TuMFsW9kIEeXi
            aPKXQa9ryfSNDhWDWloNkpGEeWif2BnHUu46Abu1UBWb0mH6VwcG1PR4qHruLis1odjQ1qnVDNfS
            EASVIppEBYjDX203ypmURIzU6h53GRRRlf1BLWkbVn9ysmDeR57Xw5Rsx/+tBlcnMrkv/40DSUke
            hQIl2JmlFrl2Caik+gU4pd20apA/pNLjBZF0OmGoS08AIR5NMd0KFa6CwZUUSHJqH5GFy5Y2yl4l
            g8K0klAS9q7L7aXI+eFQZhkwidjpxXnHPyxIGQ==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <AttributeService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.$name.com/saml/AA/SOAP" />
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
  </AttributeAuthorityDescriptor>
  <Organization>
    <OrganizationName xml:lang="en">$org</OrganizationName>
    <OrganizationDisplayName xml:lang="en">
    $org</OrganizationDisplayName>
    <OrganizationURL xml:lang="en">
    http://www.$name.fr/</OrganizationURL>
  </Organization>
</EntityDescriptor>
EOF
      ;
}

=head4 expectXPath($xml_string, $xpath, $namespaces, $value, $message)

Match a XPath expression against the provided string, and verify that the correct value is

=cut

sub getXPath {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $string_or_dom, $xpath ) = @_;

    my $dom =
      ref($string_or_dom)
      ? $string_or_dom
      : XML::LibXML->load_xml( string => $string_or_dom );
    return unless ok( $dom, 'XML successfully parsed' );

    my $xpc        = XML::LibXML::XPathContext->new($dom);
    my $namespaces = {
        samlp => 'urn:oasis:names:tc:SAML:2.0:protocol',
        saml  => 'urn:oasis:names:tc:SAML:2.0:assertion',
        md    => 'urn:oasis:names:tc:SAML:2.0:metadata',
        sig   => 'http://www.w3.org/2000/09/xmldsig#',
    };
    if ( ref($namespaces) eq "HASH" ) {
        for my $key ( keys %{$namespaces} ) {
            $xpc->registerNs( $key, $namespaces->{$key} );
        }
    }

    return $xpc->findnodes($xpath);
}

sub expectXPath {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $xml_string, $xpath, $value, $message ) = @_;

    my ($match1) = getXPath( $xml_string, $xpath );
    return unless ok( $match1, 'Found a match for XPath Expression ' . $xpath );

    if ( ref($match1) eq 'XML::LibXML::Attr' ) {
        if ($value) {
            is( $match1->value, $value, $message );
        }
        return $match1->value;
    }
    elsif ( ref($match1) eq 'XML::LibXML::Text' ) {
        if ($value) {
            is( $match1->data, $value, $message );
        }
        return $match1->data;
    }
    else {
        fail( "Unexpected XPath result: " . ref($match1) );
    }
}

sub expectSamlRequest {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($string) = @_;
    my ($sr)     = $string =~ m/SAMLRequest=([^&]*)/;
    ok( $sr, "Found SAMLRequest" );
    return decode_base64( uri_unescape($sr) );
}

sub expectSamlResponse {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($string) = @_;
    my ($sr)     = $string =~ m/SAMLResponse=([^&]*)/;
    ok( $sr, "Found SAMLResponse" );
    return decode_base64( uri_unescape($sr) );
}

sub normalizeX509Data {
    my ($data) = @_;

    # Remove heading lines
    $data =~ s/^---.*---$//mg;

    # Remove heading/trailing ws
    $data =~ s/(?:^\s+|\s+$)//g;

    return $data;
}

sub expectMetadataCerts {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $doc, $expected_signing_keys, $expected_encryption_keys ) = @_;

    my @signing_keys = map { $_->data } getXPath(
        $doc,
'(//md:IDPSSODescriptor | //md:SPSSODescriptor)[1]/md:KeyDescriptor[@use="signing"]/sig:KeyInfo/sig:X509Data/sig:X509Certificate/text()',
    );

    is_deeply(
        [ map { normalizeX509Data($_) } @signing_keys ],
        [ map { normalizeX509Data($_) } @$expected_signing_keys ],
        "Offered signing certs match excepted ones"
    );

    my @encryption_keys = map { $_->data } getXPath(
        $doc,
'(//md:IDPSSODescriptor | //md:SPSSODescriptor)[1]/md:KeyDescriptor[@use="encryption"]/sig:KeyInfo/sig:X509Data/sig:X509Certificate/text()',
    );

    is_deeply(
        [ map { normalizeX509Data($_) } @encryption_keys ],
        [ map { normalizeX509Data($_) } @$expected_encryption_keys ],
        "Offered encryption certs match excepted ones"
    );
    count(2);
}
1;
