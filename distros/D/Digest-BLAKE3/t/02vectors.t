#! perl

use Test::More;

use Digest::BLAKE3;

my($input_rep_len, $input_rep, $output_len, $key, $context, @cases, @hashers);

@hashers = (
    Digest::BLAKE3::->new_hash(),
    Digest::BLAKE3::->new_keyed_hash($key),
    Digest::BLAKE3::->new_derive_key($context),
);

foreach my $hasher (@hashers) {
    $hasher->hashsize($output_len*8);
}

plan(tests => 3*@cases);

foreach my $case (@cases) {
    my($input_len, $input);

    $input_len = $case->{input_len};
    $input = substr(
	$input_rep x (($input_len+$input_rep_len-1)/$input_rep_len),
	0, $input_len);
    foreach my $hasher (@hashers) {
	my($mode);

	$mode = $hasher->mode();
	is($hasher->add($input)->b64digest(), $case->{$mode},
	   "$mode $input_len");
    }
}

# derived from test_vectors/test_vectors.json in the BLAKE3 repository

BEGIN {
    $input_rep_len = 251;
    $input_rep = join("", map(chr($_), 0..$input_rep_len-1));
    $output_len = 131;
    $key = "whats the Elvish word for friend";
    $context = "BLAKE3 2019-12-27 16:29:52 test vectors context";
    @cases = (
	{
	    input_len => 0,
	    hash => "rxNJufX5oaagQE3qNtzJSZvLJcmtwRK3zJqTyuQfMmLgDwPntprya3+q8J/NMzBQM43f4IW4zIacqYsgbAgkOib1SHeJ6PZgr+bJnvngxSuS5zkwJKgEWc+R9Hb5/9vacAHCLhWbQCYx8nfKlvLe/fEHgoIxTnY2maMcU2MWVCHM4U0",
	    keyed_hash => "krK3VgTtPHYfnW9iOSyKkietDqPwlXPng/FJik7WDSaxgXGi8ipLlIIscB8QcVPbokkYxLrk0pRcIOzhM4difTtzy/l7eX1eWZSMfveI9UNy30XkXkKTx9wYwdQRRKl1i+WJYIVr4eq74iwmUxkN5WDKOyrEqmkqkhBpQlTDcehRvI8",
	    derive_key => "LMOXg8IjFU/qjft8GxZg8qwty9HB3oJ3sLDdObflDX2QVjDIvikN/PPmhC8Tvd1XPAmMPxc2Hx8ga4ytnQiKpKP3RnUsawzmqDsNqB1ZZJJXzfjrPp99SZjkECH6wRne77iWIkrJn4YAEfc2Cebg5FQPk7Jz5WVH39OqGgNbpmidiaA"
	},
	{
	    input_len => 1,
	    hash => "LTre3/EbYfFMiG41r6A2c23Nh6dNJ7XBUQIl0PWS4hPDpsuL9iPiDNtTX40aX/uGNC2cC2Sso7zh0x9grfoTezWK1Nefl7R8PV558Xnfh6O5d274Ml+DKYhrpC8H+xOLtQL0CBy87DGVxYcebCPizJfTxpphProTHl8TUfPx2nhlReU",
	    keyed_hash => "bXh43/8vSFY105ATJ4rhTxRUuMCjotNLwas4IoqAyVtlaMBJBglBMAb71CjrP9FOd1bZD3Okcl+tFH979w/WHE4M9wdIhekrDj8SWXi0FUmG1PsgKj8zGj+2zzSaOnDkmZD5j+Qol2HIYCxOarETjTHTtiIYB4svO6mojh0I0N1M6hE",
	    derive_key => "s+LjQKEXpJnGzyOYoZ7g0pzKK7dATHMGM4JpO/ZssGxYJ7kb+Im2uXxUd/U1Nhyu/KC12MR0ZEHFdhcRGTMViVBnD5qooF15HarhCsaDy++Pr4l8hOYRSlnSFzw/QXAjo11pg/LH36V+f8VZrXUdv7n/qznC74xKr+vJrpc6ZPDHZVE"
	},
	{
	    input_len => 2,
	    hash => "e3AVu5LPCzGAN3AqbN2B3uQSJPc0aEwsEizWNZyx7mPYOGsi4t3AWDa3wbtpPZKvAG3rX/vExw+0TQGV0MbyUvqsYWWe+GUjqhZRf4fLXxNA5yN1arZe+y+Rlk4UOR3ipDImOm+vHRRpN7NaM2IcEtAL6CI6fxkZzsCs0SCX/zqwCrE",
	    keyed_hash => "U5Ldrg4KadX0AWBGLL2b2Ik3UIL/IkrJx1iAK3pv0gqf+/fv0T6Ymmwkb5bTqWudJ58sTmP7C9/2M5V6z1DuGl9li+FEurD28WUA3uSqWWf8LFhthaBMrd7JD/+3Yz9GpgeGAkNTueXOvid/zZUUIX/uImfc2o97MWl7fFT6tqk5v48",
	    derive_key => "HxZlZaffAJjuZZItf+pCX7GLmUPxnWFh4tF5OTVhaObapZyuGYkrLVT2/J9HXSYDH9HCKuCj6O972yP0UqFeACdinS6Gexux5qshxxKXN3dQgmxATfzMJAa9V6g3dfieCwdeWadzIyZxXvkSB44hOUT0kK1oA3VXUYt5wAht5tb2zdI"
	},
	{
	    input_len => 3,
	    hash => "4b5Neoq1VgqkGZ7qM5hJuo4pPVXKCoEAZybRhFGeZH9bSbgvgFpTjGiRXBroA1yQD9HUsTkCkg/QXhRQgi823pRUt+mZbeSQDI5yNRKIP5P0NF+KWL/mTuONOtcasCd2XSXN0ORIMoqOemg7mmr4sK+U+gkBDZGGiQsJaghHHkIwoTQ",
	    keyed_hash => "OeZ7drWgB9SSGWl3n+Zm2me1ITsJYISrZ0dC8NXsYrm5FC0PqwjhsWHv27KNGK/GTY9yFgyVjlOpUM3s+RwaG7qxqcDwHe92Knfi6FRdTewkHpiom22y6aWwcPwRDKriYiaQvXt2wCq2B1Cj6nVCamu4gDw3D/5GXwf7V975Xfdyw58",
	    derive_key => "RAq6NcsAa2H8F8BSklXeQ478BqjJ6/Py3aw7WoZwV5fyfi6RRXT02H7ATDeeEniezL+8FYkmJgQnB4Atvk6Xw/9Z3KgMHlQka20FUVT3NIo5t9CYsrSCTr6Q4QTnY7KkR1EhMs7eFiQ0hKVaTkCoV5ADi7Dc92LowFPKuuQbviKlv/c"
	},
	{
	    input_len => 4,
	    hash => "8w9aso/gR5BAN/d7baT+oeJyQcXRMmONi+3OnUBJTzKPYDukVkRT4Gzc7my+copFGbvm8NQeihS1siUXSlZtv6YbVq+x5FLcCMgE+MMUPJ4sxKMbtzi/jBkXtVgwxuZXlyEXAdwLmNqh+uqm7p5Wq2Bs4DoaiB6PFOh6Ss9GRics/RI",
	    keyed_hash => "dnHd5ZDJXVrJYWZR/1qgonvuWROjSOBTuKqRCJF/4HARbArP8/DR+perONgT/UZQYIkRgUfYM5MBmwaKVdZGJR7PgRBfeY12oQrkE/PZJXh9Yhan60ROUQ/VaRbx11OlVE7PAHITShRrJhW0L1DBefVrj64HiACOPifGdII0niScuGo",
	    derive_key => "9GCFyBkNaQIjac4aGIgOmzacE165PzxjVQ0+djDpEGD719j0JYvsnaTgUET4i5GUT3yrMXovDBgnlimjhn+tBmLJrU1CxvJ+WxJNoXyMTzqUoCW6XRtiNobGCZ0gKnMXqC49ldrkaofeBVXXJ6XfVd5E2reZog3/4jlZTW6Z7ReVCRA"
	},
	{
	    input_len => 5,
	    hash => "tAtE39l+eoSplqka+LhRiMZsEmlAunqtLnrms4VAKqLrz9rGxdMsMSCeH4GkVHUSgNtklCzjlRBOHk6spiYH3hwsp0glF1TqW76MIBUOf0fv1XASxjs8amYy3Bx80V8+HJmZBAN9YPrC65OX8q2+RY1/Jk5k8ec6qSezCYjirtLwNiA",
	    keyed_hash => "c6xp7s8oaJTYECAYpvxyn0sfQkfTcD9pvcal/j4MhGFqsZnR8vPlO/+xfwoiCf6LT31Me65Zwrx9AfH/lMZ1iMxrOPpgJIhvLAeL/gm12eZYTNbFIcO7UvTedoezcRei277A1Z6S+pqMwyQNRDL5F1eqvK4D6HQx2sAD59c1dL/dghg",
	    derive_key => "HyTtpp28t1KEfsPrtd1Cg22G5YUAx8mNkG7Ngu2a5H9vSKP2fk5DMpyaibHKUmubNcv30lweNTuv+1kP15vljdtscR8aa2DphiC4UcaIZwQS/LBDVle6a2ONIfDyoE8vawvYg0g3sQ5DjV9MfCxxKZz3WG6pFE7QklPVH49U3Wv/cZ0"
	},
	{
	    input_len => 6,
	    hash => "BsTo/7aHL62W+arKXu4VU+tirtCtcZjO9C6H9qYWyERhGjDE5PN/4v4jwIg83lz3BZ2ItlfH7SCH49IQkl7ecWQ11tXYJZeh5SuVU5GegE9WVieL1zmIBpLJS/8oJNjgtIysHSRoJpnkiDOJ3E8vqi6ztNtuOd69UGH/NgmRbz4HUpo",
	    keyed_hash => "gtMZnQATA1aCzH8qOZ1MISVEN2qDmqhjoPTJEiDKem3C/7OqBfJjHw+prBm26X635maeXsJUeZNQyLjRieiAeACEKlODxNkHyTLzRJCq8ABk3ozbFXNXveN8FQTSlgA0kwiHYDq8XMufUkf3kiS6/2Ego8YipG17G8ruAsUCVGCUElY",
	    derive_key => "vpazCzeRn+Q3nfvnUq53tPfiq5L3/ydDX3by8GX2pfQ1rgGh0UvVprO2nYy9NfCwHvIXP/b5tkDKC9R0jvo5i/mpwKzWpm2TMv3JtH/+KLp6tgkMJnR7hfT6si+Ta3HrP2RhPYvZ36vpu2jaGd54MhtIHlKX355A7Io9Zi8+FHnGXeA"
	},
	{
	    input_len => 7,
	    hash => "P4dw84f6rQj6qdhBTp9EmsaOb/BBf2c/YCpkaokUGf5mA2725tGo9Uuqn+0fwRx3z7nP9luukVBFAnBG6+DAG/WpQfO7D3N5HT/AuENw+fMK8M1bD8M03WH3D+tg2teF8HD+8fND7ZM7SaXKDRalA/WZo2WkKWc5JIso0aILDizIl1w",
	    keyed_hash => "rwp+w4Ku3Az9Ym5J52KLx6NTpMsQiFVUGlZRv2T7sop8UDW6D0ipxz2rsr4FM9Auj9XQ1WOaGLKAO6a/Un4dFF1f1kBsQ3t5vKrWx73xz0vVaok8PrlRAzWnp5hUjGdT90YXvt6IvvkkukszT4hSR22QsmxdxMNmiiUZJmpWLGyANKY",
	    derive_key => "3DtkhfnZSTUylEKRaw0FloW6gVofoqFBByF0U6f8nw5mJm2y6nyWhD+dggjmAKc/f0Wy9VuebWp8zwXarmOj/dELJawL0uIkzoKR+IwFl21XXfmYR324b7LPu/kXJdYstXrP6zwtlzuJtQPCtg3ehaeAK2ncGsIAfVYjy+qMv7axgfU"
	},
	{
	    input_len => 8,
	    hash => "I1EgfQT8Fq3kPMqwhgCTnHwfpwpcCqynYGPQTDIo6utyXW1Gzu2PeFq58vmwas/jmMZpnGEp2ghMtTEXdEWmgolPloXq+DaZkiHRfJpko6BXAAUkzSgjmG2zeLB0KQoam5OiLhNe0sFMfiDG0EXNALkDQAN0EmZ26niHTXny3XiDz1w",
	    keyed_hash => "vi9UlcYcuhuzSKNJSMAEBF471Nro8P6Cv0TQ2iRaBgBI615ozm3qHrAinhRPV4s6p+n0+F/r0TXfhSXm/kDG8DQNE90JslXM1REqlCOPK+PAtbfs3gZYBCapPgcIVVomUwWr+G2HTjS0mVt4jjeoI0kfJRJ6UC/gcEuqa/3wTnbBMnY",
	    derive_key => "KxZpeM7xTZ1DgEbHIFGdixytcH4Zl0bxVi0Mh/vTKUDw4lRalmk6ZmVCJeu6rHbQk7+pzY9SWlOsuSqGGpjELn0cSuguaKtpHVEAEu3Spyj5jNR5TvdX6U1lRpYbTygKUarDOcyVtkqSuDzD8m2K+N+0wJHCQKzbTUdyjSPnFIcg7wQ"
	},
	{
	    input_len => 63,
	    hash => "6bw3pZTarYO+lHDff3s3mCl8PYNM6AuoXW4gdie323sRlwErHn2a9NfLe90fO7SakKm13sPqK7xurrznf05HDL9Ghwk7U1LwTkpFcPuiMxZOasw2kA410YWIaoJ/fqm9weXDzoiwlaIA5iwQwEOz6bxsubasTfpReUsCrOn5h3kEB1U",
	    keyed_hash => "ux611K+nk8Hr3Z+wje9sNtEAlphq4M/hSM0QEXDON66gWmPXSoQK7NUU9lTwgOUaxQ/WF9ImENkXgP5rB6JrCEers4KRBYyXR0723dGQ0w/DGBhcCcoVidICTwpvFtRfEWeDd0g/pcAFsqEHy5lD5dpjTnBGhV6qiIZj3lXWRxNx1V0",
	    derive_key => "tkUeMLlTwgbjRkTGgDck6dJyXgiTA5z8SVhPmR9FGvO4no/1ctPaT0AiGZuVY7nXDrthbv/wdj6avscbVQ8TceIzMZxMTnTak2uo5buymlmOAHoLv6kpyZc4yizAmNWRNNEf8wDDn4Li/On38PomZFlQP2SrmRO+/GX93EdPbcHGdmk"
	},
	{
	    input_len => 64,
	    hash => "Tu1xQepKXNS3iGBr0j9G4hKvnKzrrNx9H0xtx/JRG5j8nMVsuDH/4z6o5+HR3wmybv0nZ2cAZqqC0COx3+irGyt/u1uXWS1G/+PgWmqbWS4pScdBYORnQwG8P5fgSQP4xs+VuGMXTDMiiSTN73rkdVmxCylKzWYGZsRTiDNYK0P4LXQ",
	    keyed_hash => "uoztNvMncA0hPxILGiB6O4wEMwUoWG9BTQny99nMt+aCRMJgEK/D92JhW7rFUqHKkJ5nyD4v1UeM9GuegR78zJP3eiGxehUuusoWlXM/2whuI80OtIxBwDTVJSP8ISNuXYySVTBuSNUrpAtNrCQlZGDVZXPRMSMZr88+051y0L/Gmss",
	    derive_key => "pcSnBT+oa2R0bUu2iNBq0fAqGPzpr9PoGP76pxJr9z6blJOpvv6+C/DJUJ+zEFz6DiYs3hQaqOPywvd4kLtkpMypaSKiHq0RH2M4rVJE8sFcRMtZVEOsKsKUIx4xvkpDB9CpHodNNvyYUq6xJlwJtuDNp8N+9ob7vKuX6P9mcYvgSLs"
	},
	{
	    input_len => 65,
	    hash => "3h5foL5w320r6P/9DpnOqo626Mk6Y/LY0cMOy2smPe4OFuCkdJ1oEd0dbRJlwpcpsbdamsNGz5Pw4dcpbfz9QxOzoif6qq93V8yVtOh6Sb47iicKEgICM1CbHDYys0he7zCdCrxKSmlsnezG6QRUtTsAD0VqPxAHkHK6r3qYFlMiHyw",
	    keyed_hash => "wKTt76LSrMuSd8NxrBL827UpiKhu3FTwcW4VkbQybnLV55X0allrAtPUv7Q6utHl0ZIRFSci7B8g/vLNQT48IvL8XaPXMEEnW+bt41F7O58PxnreWVamcri3XZbLQylLkEFJfekmN+0/JDkiXmg5EMs66SM3REnKeI+w+b6pJzG8Jq0",
	    derive_key => "Uf0Fw8HPvI7WfROa129c+CNs0qzSZiejDBBN/Z0/+KgrAui9NthJinWtjI6bFes4aXAoPW3ULIrnkRzFkoh/2+JqCl8L+CHNkphsYLJQLJvj+YqcEzp+gEXqhn4IKMclLnOTIffC1l2u5EaOtEKe+uRppCdj8flJd0NdENzK4+Pc6I0"
	},
	{
	    input_len => 127,
	    hash => "2BKT/ahj8AjAnpL8OCqB9aC0oSUcuhY0AWoPhqa9ZA3jE31HcVbR/eVrDPNvjvGLRLLXmJe+zhIidTmsmuClEZ2kdkTZNNJudNwxYUXcuLtprD8uBcJC3W7gZIT8sOlW3EQ1W0UsXiu7Xitm6Z9d1EPQy8qq/Uvuuu0kri+LtnK873g",
	    keyed_hash => "xkIArn3681V3rFqVIcR4Y/txUUo7ytGIGSGLgY3oWBjuejF6rMwUWPeNb2XzQn7JfZwK2w1trNRHE3S2Ibe181zVRmPGTb4Lni2VYy+ExhExPqW9kLcc6Xs89kV3bzrcEeJ9E1y625h1wr+NOuawL4oCBqugw1v+QldAEZMcmiVc5tw",
	    derive_key => "yRwJDO7jo6yBkC2jGDgBJiW7zXP8uS59flb3jeuk8MP+6zl0MGlmzLPjxpwzfvikVmCtAlJjBv1oXIhUKtAPdZr23RrcLlDCuKrJ8MUiH/SBVlz2RVt3JRWmlGMiMgLlw3F0PjUhC7u6vYllFoQQf9n+STyTe+FuOc+nCEo2IHyZvqM"
	},
	{
	    input_len => 128,
	    hash => "8X5XBWSyZXjDO7f0RkP1OWJLBd8adsgfMKzVSMRLRe+mn6ugkUJ/nFxMqoc6oHgoZR8ZxVuthcR9E2ixHG/ZnkfsulggoDJZhNdP4+QFhJTKEuPx0yk9ABCpci997mT3Ekb3XpNh9EzI4hShAGUNsTE/92qfk+xuhO23rdHLSpUBmww",
	    keyed_hash => "sE/hVXdFcmf/O288lH2TvlgefjpLAYZ5El6vhvamKOzYa74AAfEL2kfmB3tzUBb8qBGdoRNI2TyjArvRJb3g2ytQ7b5yimILudPm9wYoau3qlzQlwLnu34o4hzVEz5G630mtkqY1qT9x3fzuHq5TbCXRsnCVa+FliO8c/vLx0V9lC9U",
	    derive_key => "gXIPNEUvWKASCli2tGCDhLXFHRHznOlxYaDA5ELKAiVQ581lHjEvC0xq+zw0iuXdF9Kyn6s7iU2aADTHsE/ZGQy9kAQ/9l0WV7vAW/3s8ol92JTHobVGVtWaULURkKnaRNtCYmatbOfBc6jAu+CRt15zS02ttZsoYc0lGLTnWR5Lg8k"
	},
	{
	    input_len => 129,
	    hash => "aDqq6fPFujfqrwcq7Q+eMLrAhlE3uuaLH95Moq69yxL5b/p7Nt14ujIb5+hC02SmKkLjdGaByLrOGKSop5ZJKFxxJ7+P6/Elvp3jlYbSUfDUHaIJgLcNNePawO7lnkaKiU+n5qBxKaqtCYVfatSAFRKhFroreEHmz8ma13WUqPLRgac",
	    keyed_hash => "1KZNrmzcy6weUof1TxfF+YUQVFfBouwYeOvUtX4g048cnbAYVB7sJBt0j4dyVmW3sazj4AZbKcO8sjLJDjeJf6Wq7n4eii7PzZtRRj5CI4z91/7hrssyZ/p/ISgHkXYTKkEs2KrweRJ29rmP9nNZvYZS7zogOXbV/xzUGIVXNIe81oM",
	    derive_key => "k40tRDW+MOr9uytwMfeFfJiwSIEic5HcQNs8eyH0H8GNctD5wd5XYOGUGuvzEAtR1kZEy0WetdICWOIziSgF65iwdXDvKheHzUjhF8jWpjpo/Y/I5Z552+YxKeiDUoZXIcjV8M8YP4XgYJhgRysNYIfO/dGG2YSyFULBx4BoTtaDLY0"
	},
	{
	    input_len => 1023,
	    hash => "EBCJcO7aPrkyuqwUKMeiFjsOkkyaniWzW7pyso9wvRGhgtJ6WRsFWSsVYHUA4ejdVrxsf8BjcVt6HXN99brTM5xWd4lX2HDrlxe1fqPZ+2jRtVEnu6apBqSiS71ayy0SOjeyj56agbuq42DVj4Xl/J1198NwoMwJtlItnI2CLy8o9IU",
	    keyed_hash => "yVHs3wMojQ/Mlu40E1Y9im01iVR/LC+zbZeGRw8bnW6JAxbS5ti4wlsKWyGA+U+xoVjvUIw83kXilmvXlqaW0+E+/YYlnXVjh9m+z1yL8c4hkrhwJRUpB7bYzDPReCbYt7m8l+OMPIUQjvCfAT4BwinCCoPZ6O+sWzdHDaKFdf11WhA",
	    derive_key => "dKFsHD1ENoqG4cpt9kvmovZMzo8JIgeHRQci2Fcl3qWcQTJkQEZh6eTZVUCd/krTqkh4cbzUVO0Sq/4sKx63dXWIz2yxjS7MrUngGMDQ/sMjvsgr8WRMYyVxfRPqcS5oQNPm5zDTVVP1nv9Td6nDULzBVWaUuSS4WPMpxE7mS4hO8A0"
	},
	{
	    input_len => 1024,
	    hash => "QiFHOfCVpAbz/IPeuIl0SsAN+DHBDapVGJtdEhyFWvcc+BByZeza+FBbldj87IOpimqW6lEJ0sF5xHo4f/u0BHVvburniDtEa3DrsURSfCB1q4qyBMAIa7IrfJPUZe/Ff42Rfws4XG3yZedwA7hRApZ0hu1X21xcoXC6RBQn7Zr6aE4",
	    keyed_hash => "dcRvbz2etPVeyq7kgNtzLmwhBVRvHmdQA2h8MXGce6Sni8g4xyhS1PSchkrLetr+JHjoJK/lHIkZ0GFoQUwmXymKgJSxrYE6m4YUrKusMh8kzmHFpTRutRlSDTjsxD6JtQACNt8FlyQ+TSST/WJnMOK6F6xNiCTQnRpKj1e4Ind44t4",
	    derive_key => "c1bNdyDVtmttBpfrMXfZ+Nc6SlxeloiW62poloQwJwZsI7YB0937OR6Q1cjsze9K4qJkvOnmEroV4rydZUrxSBsuddur5hWXTxBwu6hNVoUyZaNDMLR2b4517dH0oWUEdsEIAvIrZL05GdJGuiChdVi8UcGZ797GfoCiJyUYCNjOW60"
	},
	{
	    input_len => 1025,
	    hash => "0AJ4rkfrJ7NPrs9ntP4mP4LVQSkWwf/ZfIy3+4FLhET0xKIrSzmRVTWKmU5SvyVd5gA1dC7HG9CKwnWhtRzGv+MysO+EtAkQjNoIDmJp7Us+LD99ciqkzcmNFt61VOVie+j5VcmOHV+VZakZTK0MQoX5NwAGLZWVrbmSrmj/EoAKtno",
	    keyed_hash => "NX3FXeDH44LJAP1uMgrMBBRr4B22qM5yELcYm9Zk6mk2I5a3f9wNJjSlUpcIQ3IgZsPBWQKuUJfgD/U/HhFvHNU1JyAROoN6skUsr73k1UCF2c9dIcphMHFVGyXVLmnWyBEjhytvGc07wTM+3wxSuU3iO6dyz4JjbP9FQlQKdzjVuTA",
	    derive_key => "7/qiRfBl+/gqwYaDmiSXB8O9320/3aItG5WjyXA3m8tdMQE6FnUJ6QZic6tuISO8g1tAiwZ9iPlq3bVQ2WtoUtrTjjILnZQPhtt005jHcPRiEYs10nJO+hPalxlEkdlt03w8CcvvZllT8u6F7IPYi4jRFUem+RHIIXzKRt76J1Hn860"
	},
	{
	    input_len => 2048,
	    hash => "53a2Aox80ipNC6GCqL9iIF0u9XZGfoOO1vJSm4X7okqaYL+AABQQ7J7qZpjNU3k5+tR0nt1ITLVBrO1VzZv1R2TQY/I/bx4y4SlYulz+sb9hitCUJm1Pw8lowgiPZ3RUwojGe6Dboze52Rx+G6WG3JpbwtXpDBT1OohjrHVlVGHOqPk",
	    keyed_hash => "h5zx+i6g55EmyxBjYXoFtq2dC2ltDXV88FNDn2CpndEBc7lhzVdCiBlLI+zieMMw+7hYVIXnSWfzE1KoGDqngrKyLybNytth7tGlvBRLgZj7sME6u/jjGSwUXQpcIWM7DvhgVPQoCd+CM4nuQIEaWRDcvRAYrzHDtDqlUgHtTtqsdP4",
	    derive_key => "eylFy0/vcIhcxdeKh79vYgfdkB/yOSATUf+sBOEIiiPiwRoev/zqTYBEeGe2G62xOD2ELU55ZF1I3YLMuikHacqnr46qG9eKKl5ulPvat42ce3TolIefalFSV8z2+VBW9OJTkPJPazX/u3S3ZiAlabHXl/LUvZ0XUkxyAQf5hfTdxYM"
	},
	{
	    input_len => 2049,
	    hash => "X01y9A16X4KxXKKy5Esd48LvhsQmyVwa8LaHlSJWMDCW3jHXHXQQNAOCKi4LwesZPnrsyWQ6dre7wMn5xS6Hg6rph2TKRolitcLskvDHTrVEjVGXE+CUE3GUMcgC+UjdXZBCWk7Nrezp6xeNgPJu/MrmMHNN/2M0AoWt7CrtO1EHOtM",
	    keyed_hash => "nylwCQL3yG5RTdxN8eMEnyWLJHK23VJn9hvxOYO3jdX5qIq/79+h4AtBiXHys5xkymIejrN/zqxX/QyPyOEX1DuBRHviLV2Bhvj1kZumvMaEa9fVBybAbSRWcsKtT2FwLGRkme4Rc9qgYf/hW/RaYx4pRtYWpMNFgi8RUShHEvdrKw4",
	    derive_key => "LqR3xVFcw91gZRLucrs+DnWM+ucjKCbzX7mMoby98nMW2OnnkIGoCwRrYPaiY2FvM8pGS9eNefoYIA0Gx/yb/9gIzEdVJ3p9XgnaDyntFQ9lN+qb7ZRiJ/8YTMZqcqX4weS9iwToHPQP5txEJ61WeDEaYfT/w50ZVYm9vGcPY65w9LY"
	},
	{
	    input_len => 3072,
	    hash => "uYyw/zYjvgMyazc95rkJUhhRPmTx7i7dJSXHrR5c/9KaP2sLl41mCDNcCdyUzPaC+ZUc38UBv+R7nJGJpvx7QE0SAlhQY0Gm2AKFcyL70g0+Xa4FuVyIeT+oPbHLCOfYAI0VmbYgnXgzbiSDlyTBkbKlKoBEgwbg2qhKP9tWZmGjfhE",
	    keyed_hash => "BEoOexcqMS3AKkyagYwDb/ondjaNf1KCaNLmtd8ZF3Ai8wLQUp5BdMxQfEY2cSF5degdqwK4/esNfMx1aN0iV0x4Ona+IVRBsy6RuakEvo6oH3oK/RS62O58jvwwWs5dPdYbmW/r6NpPVsoJGTWadTMhbimZ/If/fY8Xb77LPW80J4s",
	    derive_key => "BQ35f4wurWVNm7OrjJF47c2QKjL4SVlJ/q3MHgSAxGs2BBMbvW47pXO23WgvoKY+WxZdOfxDpiXQAgdgeiv+tl/x0pKSFS4mspiGjjuHvpXWRY9vLOYRhDe2MkFavmrVIodLzXnkAwpee60u+pCnp8Z+k/Chj7KDadCpMpq1wkE0zLA"
	},
	{
	    input_len => 3073,
	    hash => "cSS0lQEBL4HMfxHKBp7JImzsuKLIUM/mROMn0i0+HNOaJ647edaNidqb8lvCcTmuZaMkkYpfm3goGB5Szzc8hPNbY5t/zLuYW28vpWrqDBj1MSA0l7i706B861km8cq3TRS9ZkhtmpHrqZBZqYvRzSWHayr1p2w+nu1VTtcuqVK2A78",
	    keyed_hash => "aN7em+8AuonkPzGmgl9M9DM4n+2udcBO6fDPFqQnyVqW1to/6YUFTTR4hlvpoJIlCDmml7vadOJ56KnmnwAl5M/d1s+0NLHNlUOq+XxjXRtFGkOGBB5LsQD15FQHy7wk+lPqLeNTbMsynk65Rm7DcJOkLPYrgpA8aWqTpQtwLIDzw8U",
	    derive_key => "cmE8nsn/fkD49cFzeExTKthS6Cfbor+FsqtLdvcHkIFXYojlUmR6nYZIHCyudcLdTnxRlfua2h71DpxQmMJJ10OSkZFEEwHGnh9IUFpDBewXeEUO5IuOadwjollg/jMHDqVJEZWZdgqKLSiuyga4xem6WLwZ4R/le27piqRLKo5rFKU"
	},
	{
	    input_len => 4096,
	    hash => "AVCUAT9XpSd7WdhHXAUBBCwLZC5TGwocj1jSFjIp6WkCielAndsbmXaOr+FiPaiW+vfhEUvr6twb4wgptvivcH2Fwpj08P9NlDiu+UgzVhKukh521BHDqREd9i0n6vhxlZrgBitUkqD+uY7z7Uryd/U5UXLb5cMRkY6gB0zgA2RU9iA",
	    keyed_hash => "vvxmCuovFxiITNjeuZAoEdMy9PxKOM98cwDVl6CBv8C7tko27bVk4B5LSq87BgCSprg4vqRK/r0t64KY+lYre1l8dXud9MkRw8pGLirInpp4c1eq90w7VtXAe8k86JlWij6xfZJQwg9sX2weeS7Joty3FTmNWm7G1cVPWGoAQDoa8d4",
	    derive_key => "Hg1/PbjEFMl8YwfL2mzSesOwMJSdqOI74aGpJK0vJbnXgDj3sZhZbGzEqcz5MiPAhyLWhPJA/2VpB17YFZH9k/n/8RELOnW8Z+QmAS5ViJWcxaTBkhc6A8AHMc+EVE9lovuTeJifculpSmo5SoowmXwuZ/laUE5jHNLF9VJGAkdhskU"
	},
	{
	    input_len => 4097,
	    hash => "m0BSs48cX8ix+f96x7J80kJIez2JDRXJahwluKoPuZUF+RsLVgChElFlLqz6lJezHNPECc4uRc/mwKAWlnMWxCa9JvYZ6rXXCvmkGLhFxgiEA5DzYWML1Jexq0QBkxY1fGHb4JHOcvwW3DQKw9bgCeBQs62sS1sskuciz/3EZQFTGVY",
	    keyed_hash => "AN+UDNNrufp8u8NVZ0Tg28gZFAGv5wUguiku48qAq7xgbbSXbP3SZq4Kv2Z9lIGDH/EuDKomjn0+VyYMCCQRWlTOWVzMiXeG2dy/SVWZz9kBVxhqRuyACmdj8cWeNhl+mTnpAICfcHfBAviIyq+GSyU7xB7qgSZW1GdC5OpCdp+JuD8",
	    derive_key => "rKUQKWJrVf2nEXtCp8IR+Mbpuk/lt6jKki80KZUA6tiol/ZqQA/tkZj9Yd0tWNOCRY5k4QASgHX8VLhgk06N4uhBcHNLBuHSEqEXEAgg28SCktFIr6UFZ7i4Sx7DNq4Q1AyMl1piSZbhLeMau+E12dFZN1c5wzN5ioDGSuiV5R4i860"
	},
	{
	    input_len => 5120,
	    hash => "nK3BX+2LXYVFYrJqlTbZcHyt7amxQ5ePMZqzQjBTWDOsxhyP3BFKIBDOgDjIU+Eh4VRJhRM/zN0KLVB+jmFeYR6aC6T0eRX0nlPXIYFqkZjosw8S0g7DaJmJF18b96MA7uDZMh+tjaIy7ObvuOn9gbQq0WH2uVUKBp5msRtASHpfUFk",
	    keyed_hash => "LEk+SOm5vzHgVToisjUDwKM4jwNc7OaOtDjSL6GUPiCbTckgnNgM58H3yadEZY5+KIRlcXrm5W1UY9T4DNsu9WSV9qT1SH9pdJrww0ws36hX8wVr+NgHM2oU17ib9ivvL7VPmvalRvgY3B6YueB/ilg02lD6KPtYdK+RvwYCDRvwEg4",
	    derive_key => "enrKyKAq3PMDjXTN0dNFJ96KD8wO4zmdEmI5fOWBf2BV0M79hNnVf+eS1lonj9IDhKxsMP2zQAkvGnSpKs6ZxIKyjw/A7zuSPlat4gxtukfkkicWYlEzfYCgN+mHrTp/cotatt+v1uKrG9WDqV2ciVupwkIsJOoPYpYfDcpFytR7+g0"
	},
	{
	    input_len => 5121,
	    hash => "YovSyyAEaUraq3u9d4ol3yXEe51BVaVfj7158v4VTP+WraqwYTphRs2qvkmMOpTlKdP8HaK9CO31TtZNQNzWd3ZH6sUdgnfXAhmpaUM0povI8PI+ILD/cK2m+ERULfoyzUIEyhhG73bYEc2ylvZeJgIn9HeqeqAIush49yJXSE8rbJU",
	    keyed_hash => "bM8cNHU+egRNuAeY7NB4Ko928zVjrMrdv7suDqSy0CQNB+Y/E2Z6jRSQ5eBPE+theuoWqMilqu0e9vveGwUV48gQULNhr26tEmAymYKQtWPjyt3q6/q1kuFV8uFh+3y6k5CSEz8j+eZSReWOwjRXt4ouihJViKrW4H1/EahbiNN1ty0",
	    derive_key => "sH8B5RjnAvfMtEomfp4RLUA6ez9Ig6R/++1LSDObPDQaCt0KwDKrWq6h5OWwBHB+xWga4Py+N5aXTAsc8xoZR0DBRRknPu2qvsgy6KeEtufPwsWVJnfmw/LDkURUCC1+sc4XZqx9daTTAB/IlUTdRrUUc4IkDWibu678NZ+2rjAmMWU"
	},
	{
	    input_len => 6144,
	    hash => "Pi5bdOBI863W0h+qs/g6pE07InivuDuAs8NRZOvsogVNdCAi2m/dpETrw4SwSlTDrFg5tJ2n059tip2wPeqzKq3hVsHAMR6bNDXN4N26Dc57JqN2ytEhKUtokZNQjdYxUWA8bduGatFsLuQVhdFjOizqCTvqcU9MXWuQNSIEWyA5XIM",
	    keyed_hash => "PWttISgdCt5bKwFq5ANMXewQyn5HX5D3bqxxOOm8jx3DV1QGAJHcXK8++r4GA8YPReQVuzQH22fmvrPRHPjk95B1YfBdrODBWAf0tfOJyEHrEU2BqCwCoAtXIGsdEfpugDSGsEilzocQWmht7gQSB+CVMj3+Fy33PeuMlTIGbYj52n4",
	    derive_key => "KpW+rmPdzlI3YjVc9LnB2PExRleAo5Eoal0Bq7VoOhWXCZ48ZIiqtsSPPBXb4ZQtIdvNwSEV0ZqLhGX7VOkFMyOpF45CdWR/Gpkn9kOeUrcDGgtGXIYaP8UxUn93WLK4iM8vIFgunixZNwnApE+cbg+LljmUiC6kFogngj7vH2QWn+8"
	},
	{
	    input_len => 6145,
	    hash => "8TI6hjFEbMUFNqn3Be5cthlCTUaIfzw3bGlbcODwUH8Yos/dc8bjnddc58HG4+8jj9VEZfBTsl0hBEzLIJO+sBUBVTKxCDE7WCnDYhzjJLjhQikJG3yT8y2y5OYxJqN30qY6NZeZfU8culkwnLSvJAunDOv/miPV4/8M2uLP1U4HACI",
	    keyed_hash => "msMB6eOeReMlCn47PfcBqg+2iJ+9gO7s8o28YwD7xTnzwYTKL1l4DieldsHR+5dy6Z/ReIHQKsff05Z1rKkYRTKD7YwxaQhe9KRmuRwWScw0Hf3uYOMiMfw0ycTguaK6h8qPNyWJx0TBX9b5he7BXpgTbyW+60sTxOQ9yEq8x5zUZGw",
	    derive_key => "N5vMYdAFHdSJ9obBPeANWxTFBSRRA9wEDZ5N0frKuOURRJPQKb29KVqqdEpZ4x81x/Utupw2Qvdz3QtCYqmYCirvgRaX4TBdN7qdi22FDvB/5BEImTGAz3ea7s42NwTHZINFhgO77raTz/u+VYjR81NdytiIiT5T2XdCS7cHIBVpqNI"
	},
	{
	    input_len => 7168,
	    hash => "YdqVfsJJmpXWuAI+Kw5gTsf2tQ6AqWeLidJijpmtp3pXB8MhyDNheTua9ipA9DtSPfHIYzzstM0U0AvcecePylFluGOJP204sC/3I2xamorS26h9JMVHyrBGwp/FvB7RQuHeR2NhO7FipaU45u8F7QUZnXUfnrWNMyeRuNc/t05PzpU",
	    keyed_hash => "tCg15A6dSn9CrYzAT4WpY6duGBmDd+2Erd3q7KzG8/yi8B1Sd9abtoHHD6jTYJT3PsBuRSyA0v8iV+2C57o0hACYmmXujapwlK4JM+PSIQrGOVxK8k+RwrWQ74fXeI1wZuo+rrykwIpPFLmidkT5kITDVDcRtkoHC5TyydHYqQ0DXVI",
	    derive_key => "EcN6ESdlNwyUpRQV0NZRGQwohWbildUF3v2tiV2uIjcw1aUXWjiEFpMCBmnHY49AubwfnznPmL2npbVK4kIYqACiEWs0ZlqpXYRtl+qYi/y1PdnAVdWI+iG6eJlndupsQLxCi1PGK188zyAPZHparoBn8OoZdjkfzHKvGUUQDipty4g"
	},
	{
	    input_len => 7169,
	    hash => "oAP8elF1Sps8f64DZ6s9eC3M8ohVoD1DX4z+dGBeeBeYqLIFNL4cqesq4t8/ri6mDkjG+wuFCxOFtd4P5GDb6dn5sNjbRDXadcYBFW350Ef07eAIcy6xetwF2WGA+Kc1SFIoQHeeYGLWQ7eUeKbo285okn826/Z2/6fXLV9o8FCxGcg",
	    keyed_hash => "7ZsakiwEb9s9QjrjThQ7Bcob8otxBDKFe/c4vO2/pRE8nijXL8v8AggUzj9dT8hn8ByPW2yvMFs+qKi6LaOrafq8tDjxn/EfU3itRITXXEeN5CX7jm7oCbVO7JvbGEMV3IVmF8CfU0BFG/Qv0ycKewtlZhafJC5TN3dgTBGKY1glD1Q",
	    derive_key => "VUsKXv6p7xg/L5uTG3SXmV2esm9cXG2tK5fWL8WsMdmbIGUsAW2IuiphG712FmjV7aPlaOlA+q4ksNmZHDvSWmX3cLif3K2ryz0anBy2PmlyHKzxrmn+/c7x4+9BvFMSzMFyIhmeR6JlUsatxGDPR6cjGctQOTadAGDq6lnWxlEw8d0"
	},
	{
	    input_len => 8192,
	    hash => "queSSEyO/k8Z4sp9Nx2MRn/7EHSNiloa5XmUj3GKKmNf5Ron2wRaVnwa1RvlqjTAHGZRxNm1taxdD9WM8Y3WGkd3hWa3l6jGffex1guXsZKI0th3uy30F6zgCdywJByhJX1icStqQEO0/zP2kNhJ2pHqO/cR7Vg8t7en2ig5unEwm78",
	    keyed_hash => "3JY3yIRadwtMv3a42uwO6/fcLqwRSYUX8I1EyPwA1YpINEZBWdy8EqC6DG1utBusDtZYXKv+Cso2o3XmxUgMIq/cQHhcFw9aa4oRB9vuKCMY0A2RWsntEUOtQHZewSAELuEhzSuqNiUMYYra+eJyYP2i+U3qj7bwjAT48Qx4KSqkYQI",
	    derive_key => "rQHXrkrQWbDTO6o8ATGdz4CICU0DWeX9RdauqostDD1MnliVhVNRO2f4T46sZTrusCrh1Wctzs+RzZmFoOZ/RQGRDsuiVVU5VCfMxyQdcNwhwZDiqt7odeWq5r8ZEoN+U0Edq/elbL+OT7eAQysNf+bOxFAkoHiM9YdGFkB3V+nmvvc"
	},
	{
	    input_len => 8193,
	    hash => "urbAnLjOjPRZJhOY0ueu81cAv0iBFs65SjbQ9fG3vDuyKCqmm+CJNZ6hFUuakobEpWr03pdamqSlxJdlSRTSeb6mC7bSz3IlovoP9e9Wu+SxSfPtFYYPeLTirQThWON1weDAtVHNffyC8bFVwRtrPtUeye2zDRM2U7tXCdHb1V9OH/Y",
	    keyed_hash => "lUoqdUIMjWVH47pbmNlj5vpkka3cjAIxicxRmCG0ofXwMihkj9mDrvBFwvqCkJNLCGa2FfWFFJWH3aIpkDmWUyiDWisY8dY7fjAPx2/yYLVxg5/kSHak6uZsusjGdpRBHtfgnfUQaKIsbmfW090syo/xLjJ1OEAGyA9NtoAj8k7rulc",
	    derive_key => "rx4DRuOJsXwjIAJwpkqk4erZjGFpXZF959WwBJHJsPEvIKAdbWIu3z3gJqTbTkUmIl3ruTwSN5NNccc0C7WRYVjL2v6awyJUdrarV6EjV9s6u616JsbmYpDkQDT7CKIKjQ7CZPMJmU0oEMSc+6aYnXq7CViXRZ9UJa20iroHxfs8g8A"
	},
	{
	    input_len => 16384,
	    hash => "+HXWZG3iiYVkbzTuE76aV2/VFfdrWwomuzJHNQQd3eSddkwnAXblPpe9/6WNVJBz8sZgvg6BKTdn7U5JKfmtNLuzmlKTNMV8Sjgf/SptS/2/FIJlGxcqqIPME0CPpndYo+R1A/k/h3IKMXcyX3gjJRuFJ19kY2qPHVmcLklyL0LpOJM",
	    keyed_hash => "np/E63zwgep8R9GAd5DtIRv+xWqiW7cDd4TBPEtwew355gGxAeTPY6QE3+UPLhhluxLtyPyhZlec4McNulpcD8lgrW83chg0FqAL0p1MbmUep2ILsQDJRJhYvxTh3cns01clWByluRYN4EBgBFmT2XJXHD6PcenQSWv6dEZWhhsWnWU",
	    derive_key => "Fg4YtYeM0N8cOvhesloNtTRNQ6b716jvTtmNBxTD9+Fg3AsfCcqjXy9Be57zCd/l69Z/TJUHmVpTE3TQmc+K4xdULohexvWJN4hk0+qYcWs7u2XvSrXgq1uymKUB8ZpB7BmvhKXmtCjs2BOxpH7ZHJZXw/uhHEBrwxZ2i1j2gCyem1c"
	},
	{
	    input_len => 31744,
	    hash => "YraWDhpEvMHrGmEajWI1trS3jzLnq8T7TGzczpSJXEeGDMUfKwwop7dzBL1V/nOvZjwC0/UuoFO6Q0Mcpbq3v+ovXp1xIXcNiPcK6WSepxMIfRkU9/MSFH4kf4frLU/+8KyXi/e2V51X1TM1WqILi3exP9CXSHKKXMMnqOxHD0ATIm8",
	    keyed_hash => "76U7OJq2fFk9umJNiY0Pc1OrmeSsnUIwLuZMv5k5pBk6cljbLZzTKno+z85GFEEUsVwvy2imGKl2vXRRXUe+CLYovkILXoMPrefAgONRoHb7w4ZBrYDHNsihj+PGbOEvlcYcJGKpdw1g0PdxFbvNN4K1kwFqTnKNTAbO5FBcsMCKQuw",
	    derive_key => "OXcq74Dg6+YFljYeRbBh6PQXQp1SkXG2dkRowiko4o6XWa3reXo/v3cbG86jAVCgIOMXmCvw1ufRTdnwZLwRAlwl8x6BvXipIdsBdPA91IHTDpP9jpD4sv7iCfhJ8tKlLzFxmkkPsLp66h4JgU7pEuuhEan96dXCdBhfe66LqF0wCis"
	},
	{
	    input_len => 102400,
	    hash => "vD49QaEUawaav/rTwNRIYM9mQ5Cvzk2WYfeQLnlD4IXgHFnauQjATDNCuBaUGibWnCYF6+5exSkcxV4Vt2FG5nRfBgEVbDWWy3UGWpxX81WFpS4axw9pExwj1hHOEe5KsewsAJAS0jZkjne+kpXdBCbym3ZNZd5Y630B3UIkggT0X44",
	    keyed_hash => "HDXRpYEQg/1xGfXV0boCe00BwMbEn7b/LPdTk+pdtKf5290+HYHcvKO6JBuxh2DyB3ELdRhG+q653/gmJxCZmlmyqhrKKYoDLZTqz63xqhkkGOtUgI2yO1bjQhMmaqCEmaFrNU8Bj8SWfQX4udKth6cngze+lpP8Y4o7/b4xRXTub8Q",
	    derive_key => "RlLP96PzhaYQO1wmD8FZPhPHeNvmCO+wkv5+5p326cbYOj4EG8OkjfKHn0oKPtQOfJYcc+/3QPMRegUEwt/0eG1E+xfxVJ6wulheQOwpv3cy8Lfihv+KzdxMseI7h/9dgkqYZFjcxqBKyDlpuAY3VilT31HtGn6Qp5JpJNJ2N3i+hWA"
	}
    );
}

