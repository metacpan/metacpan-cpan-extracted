#ifndef MARPAESLIF_INTERNAL_JSON_H
#define MARPAESLIF_INTERNAL_JSON_H

static const char *jsonStringRegexsp[_MARPAESLIF_JSON_TYPE_LAST] = {
  /* Strict */
  "\"(?C50)(?:((?:[^\"\\\\\\x00-\\x1F]+)|(?:\\\\[\"\\\\\\/bfnrt])|(?:(?:\\\\u[[:xdigit:]]{4})+))(?C51))*\"(?C52)",

  /* Extended */
  "\"(?C50)(?:((?:[^\"\\\\]+)|(?:\\\\[\"\\\\\\/bfnrt])|(?:(?:\\\\u[[:xdigit:]]{4})+))(?C51))*\"(?C52)"
};

static const char *jsonStringRegexModifiersp[_MARPAESLIF_JSON_TYPE_LAST] = {
  /* Strict */
  "u",

  /* Extended */
  "u"
};

static const char *jsonConstantOrNumberRegexsp[_MARPAESLIF_JSON_TYPE_LAST] = {
  /* Strict */
  "true(?C60)|false(?C61)|null(?C62)|(?:-?(?:0|[1-9][0-9]*)(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?)(?C63)",

  /* Extended */
  "true(?C60)|false(?C61)|null(?C62)|(?:[+-]?(?:[0-9]+)(?:\\.[0-9]+)?(?:E[+-]?[0-9]+)?)(?C63)|(?:\\+?Inf(?:inity)?)(?C64)|(?:-?Inf(?:inity)?)(?C65)|(?:\\+?NaN)(?C66)|(?:-?NaN)(?C67)"
};

static const char *jsonConstantOrNumberRegexModifiersp[_MARPAESLIF_JSON_TYPE_LAST] = {
  /* Strict */
  "",

  /* Extended */
  "i"
};

#endif /* MARPAESLIF_INTERNAL_JSON_H */
