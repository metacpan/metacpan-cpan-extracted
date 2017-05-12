create table all_subjects (
word varchar(32),
word_stem varchar(32),
word_no integer,
valence_mean float,
valence_sd float,
arousal_mean float,
arousal_sd float,
dominance_mean float,
dominance_sd float,
word_freq float,
primary key(word)
);

create table male (
word varchar(32),
word_stem varchar(32),
word_no integer,
valence_mean float,
valence_sd float,
arousal_mean float,
arousal_sd float,
dominance_mean float,
dominance_sd float,
word_freq float,
primary key(word)
);

create table female (
word varchar(32),
word_stem varchar(32),
word_no integer,
valence_mean float,
valence_sd float,
arousal_mean float,
arousal_sd float,
dominance_mean float,
dominance_sd float,
word_freq float,
primary key(word)
);

