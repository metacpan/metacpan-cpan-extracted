CREATE TABLE sessions (
    id varchar(64) not null primary key,
    a_session text,
    _whatToTrace varchar(64),
    _session_kind varchar(15),
    ipAddr varchar(64),
    _utime bigint,
    _httpSessionType varchar(64),
    user varchar(64),
    mail varchar(64),
    _session_uid varchar(64)
) DEFAULT CHARSET utf8;
CREATE INDEX i_s__whatToTrace ON sessions (_whatToTrace);
CREATE INDEX i_s__session_kind ON sessions (_session_kind);
CREATE INDEX i_s__utime ON sessions (_utime);
CREATE INDEX i_s_ipAddr ON sessions (ipAddr);
CREATE INDEX i_s__httpSessionType ON sessions (_httpSessionType);
CREATE INDEX i_s_user ON sessions (user);
CREATE INDEX i_s_mail ON sessions (mail);
CREATE INDEX i_s__session_uid ON sessions (_session_uid);

CREATE TABLE psessions (
    id varchar(64) not null primary key,
    a_session text,
    _session_kind varchar(15),
    _httpSessionType varchar(64),
    _whatToTrace varchar(64),
    ipAddr varchar(64),
    _webAuthnUserHandle varchar(128),
    _session_uid varchar(64)
)  DEFAULT CHARSET utf8;
CREATE INDEX i_p__session_kind ON psessions (_session_kind);
CREATE INDEX i_p__httpSessionType ON psessions (_httpSessionType);
CREATE INDEX i_p__session_uid ON psessions (_session_uid);
CREATE INDEX i_p_ipAddr ON psessions (ipAddr);
CREATE INDEX i_p__whatToTrace ON psessions (_whatToTrace);
CREATE INDEX i_p__webAuthnUserHandle ON psessions (_webAuthnUserHandle);

CREATE TABLE samlsessions (
    id varchar(64) not null primary key,
    a_session text,
    _session_kind varchar(15),
    _utime bigint,
    ProxyID varchar(64),
    _nameID varchar(255),
    _assert_id varchar(64),
    _art_id varchar(64),
    _saml_id varchar(64)
)  DEFAULT CHARSET utf8;
CREATE INDEX i_a__session_kind ON samlsessions (_session_kind);
CREATE INDEX i_a__utime ON samlsessions (_utime);
CREATE INDEX i_a_ProxyID ON samlsessions (ProxyID);
CREATE INDEX i_a__nameID ON samlsessions (_nameID);
CREATE INDEX i_a__assert_id ON samlsessions (_assert_id);
CREATE INDEX i_a__art_id ON samlsessions (_art_id);
CREATE INDEX i_a__saml_id ON samlsessions (_saml_id);

CREATE TABLE oidcsessions (
    id varchar(64) not null primary key,
    a_session text,
    _session_kind varchar(15),
    _utime bigint,
    user_session_id varchar(128),
    _oidc_sid varchar(128),
    _oidc_sub varchar(128)
)  DEFAULT CHARSET utf8;
CREATE INDEX i_o__session_kind   ON oidcsessions (_session_kind);
CREATE INDEX i_o__utime          ON oidcsessions (_utime);
CREATE INDEX i_o_user_session_id ON oidcsessions (user_session_id);
CREATE INDEX i_o__oidc_sid       ON oidcsessions (_oidc_sid);
CREATE INDEX i_o__oidc_sub       ON oidcsessions (_oidc_sub);


CREATE TABLE cassessions (
    id varchar(64) not null primary key,
    a_session text,
    _session_kind varchar(15),
    _utime bigint,
    _cas_id varchar(128),
    pgtIou varchar(128)
) DEFAULT CHARSET utf8;
CREATE INDEX i_c__session_kind ON cassessions (_session_kind);
CREATE INDEX i_c__utime        ON cassessions (_utime);
CREATE INDEX i_c__cas_id       ON cassessions (_cas_id);
CREATE INDEX i_c_pgtIou        ON cassessions (pgtIou);
