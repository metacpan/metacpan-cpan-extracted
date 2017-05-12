Lingua::RU::Translit module converts from russian
"translit" encoding - russian text written using latin1 charset -
to russian in koi8-r: sub translit2koi

Convertion russian-to-translit is lossy, so this module uses Hidden
Markov Model to find the most probable original russian text.
Leaves Russian in cyrillic or native English as is.

Can be very useful in email applications (email in "translit" Russian
are way too common, because not everybody can or know how setup his mail
client for Cyrillic).
I personally use it in xchat plugin.

possible todo:

add koi2translit - it's trivial
tr/.../.../; and few s/.../.../g; everybody can write it in a minute,
but I could add it here for completeness :)

Extend decoder by
 * addind feedback
 * loadable transition tables
 * loadable characted equivalent tables
 * more bullet-proof HMM
 * spell-checker (or simpe list of exceptions)
 * neural net instead of HMM ?

