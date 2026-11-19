/* --- Time zones from the TZif database, without touching the process TZ ---
 *
 * Ported from ClickHouse::Encoder's datetime.c: TZif v1-v3 transitions plus
 * the POSIX footer rule (including permanent DST). Wall times resolve like
 * the server: a fold takes the earlier instant, a gap the offset in force
 * after the transition. Zones load lazily and stay immutable. */

typedef struct {
    int kind, month, week, day, seconds, clock;
} ch_tz_rule_t;

typedef struct ch_tz_s ch_tz_t;
struct ch_tz_s {
    ch_tz_t *next;
    char *name;
    int64_t *transitions;
    unsigned char *indices;
    uint32_t count, type_count;
    int32_t offsets[256];
    int footer, has_dst, standard, daylight;
    ch_tz_rule_t start, end;
};

static const int ch_tz_mdays[] = {31,28,31,30,31,30,31,31,30,31,30,31};

static int ch_tz_leap(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}

static int64_t ch_tz_year_days(int year) {
    int y = year - 1;
    return 365LL * (year - 1970) + y / 4 - y / 100 + y / 400 - 477;
}

static int ch_tz_epoch_year(int64_t epoch) {
    int year = 1970 + (int)(epoch / 31556952);
    while (epoch < ch_tz_year_days(year) * 86400) year--;
    while (epoch >= ch_tz_year_days(year + 1) * 86400) year++;
    return year;
}

static int64_t ch_tz_rule_epoch(const ch_tz_rule_t *rule, int year,
                                int standard, int before) {
    int day = rule->day, month;
    int64_t days = ch_tz_year_days(year);
    if (rule->kind == 'M') {
        int weekday, length;
        for (month = 1; month < rule->month; month++)
            days += ch_tz_mdays[month - 1] + (month == 2 && ch_tz_leap(year));
        weekday = (int)((days + 4) % 7);
        if (weekday < 0) weekday += 7;
        day = (rule->day - weekday + 7) % 7 + 7 * (rule->week - 1);
        length = ch_tz_mdays[rule->month - 1]
               + (rule->month == 2 && ch_tz_leap(year));
        if (day >= length) day -= 7;
    } else if (rule->kind == 'J') {
        day--;
        if (ch_tz_leap(year) && rule->day >= 60) day++;
    }
    return (days + day) * 86400 + rule->seconds
         - (rule->clock == 'u' ? 0 : rule->clock == 's' ? standard : before);
}

/* UTC offset in seconds at an instant; NULL zone is UTC. */
static int ch_tz_offset(const ch_tz_t *tz, int64_t epoch) {
    uint32_t lo = 0, hi;
    if (!tz) return 0;
    if (tz->footer && (!tz->count || epoch > tz->transitions[tz->count - 1])) {
        int year, y, offset = tz->standard;
        int64_t latest = INT64_MIN;
        if (!tz->has_dst) return tz->standard;
        year = ch_tz_epoch_year(epoch);
        for (y = year - 1; y <= year + 1; y++) {
            int64_t start = ch_tz_rule_epoch(&tz->start, y, tz->standard, tz->standard);
            int64_t end = ch_tz_rule_epoch(&tz->end, y, tz->standard, tz->daylight);
            /* >= so a year-round DST rule (end(y) == start(y+1)) stays in DST */
            if (start <= epoch && start >= latest) { latest = start; offset = tz->daylight; }
            if (end <= epoch && end > latest) { latest = end; offset = tz->standard; }
        }
        return offset;
    }
    hi = tz->count;
    while (lo < hi) {
        uint32_t mid = lo + (hi - lo) / 2;
        if (tz->transitions[mid] <= epoch) lo = mid + 1;
        else hi = mid;
    }
    return tz->offsets[lo ? tz->indices[lo - 1] : 0];
}

/* Instant of a wall time given as seconds-as-if-UTC: the offsets two days
 * either side are the candidates (wider than any real offset change, such
 * as Samoa's 24 h jump); a fold takes the earlier instant, a gap the
 * offset after the transition. */
static int64_t ch_tz_wall_to_epoch(const ch_tz_t *tz, int64_t wall) {
    int offs[3], i, found = 0;
    int64_t best = 0;
    if (!tz) return wall;
    offs[0] = ch_tz_offset(tz, wall - 2 * 86400);
    offs[2] = ch_tz_offset(tz, wall + 2 * 86400);
    if (offs[0] == offs[2] && ch_tz_offset(tz, wall - offs[0]) == offs[0])
        return wall - offs[0];
    /* the offset at the wall time itself covers two changes in the window */
    offs[1] = ch_tz_offset(tz, wall);
    for (i = 0; i < 3; i++) {
        int64_t t = wall - offs[i];
        if (ch_tz_offset(tz, t) == offs[i] && (!found || t < best)) {
            best = t;
            found = 1;
        }
    }
    return found ? best : wall - offs[2];
}

static int ch_tz_number(const char **p, int limit) {
    int n = 0;
    if (**p < '0' || **p > '9') return -1;
    while (**p >= '0' && **p <= '9') {
        int d = *(*p)++ - '0';
        if (n > (limit - d) / 10) return -1;
        n = n * 10 + d;
    }
    return n <= limit ? n : -1;
}

static int ch_tz_abbreviation(const char **p) {
    const char *start = *p;
    if (**p == '<') {
        (*p)++;
        while (**p && **p != '>') (*p)++;
        if (**p != '>') return 0;
        (*p)++;
        return *p - start >= 3;
    }
    while ((**p >= 'A' && **p <= 'Z') || (**p >= 'a' && **p <= 'z')) (*p)++;
    return *p - start >= 3;
}

static int ch_tz_seconds(const char **p, int *out) {
    int sign = 1, h, m = 0, s = 0;
    if (**p == '-' || **p == '+') sign = *(*p)++ == '-' ? -1 : 1;
    h = ch_tz_number(p, 167);
    if (h < 0) return 0;
    if (**p == ':') { (*p)++; m = ch_tz_number(p, 59); }
    if (**p == ':') { (*p)++; s = ch_tz_number(p, 59); }
    if (m < 0 || s < 0) return 0;
    *out = sign * (h * 3600 + m * 60 + s);
    return 1;
}

static int ch_tz_parse_rule(const char **p, ch_tz_rule_t *rule) {
    rule->clock = 'w';
    rule->seconds = 7200;
    if (**p == 'M') {
        rule->kind = *(*p)++;
        rule->month = ch_tz_number(p, 12);
        if (rule->month < 1 || *(*p)++ != '.') return 0;
        rule->week = ch_tz_number(p, 5);
        if (rule->week < 1 || *(*p)++ != '.') return 0;
        rule->day = ch_tz_number(p, 6);
    } else {
        rule->kind = **p == 'J' ? *(*p)++ : 'n';
        rule->day = ch_tz_number(p, 365);
        if (rule->kind == 'J' && rule->day == 0) return 0;
    }
    if (rule->day < 0) return 0;
    if (**p == '/') {
        (*p)++;
        if (!ch_tz_seconds(p, &rule->seconds)) return 0;
        if (**p == 's' || **p == 'w') rule->clock = *(*p)++;
        else if (**p == 'u' || **p == 'g' || **p == 'z') { rule->clock = 'u'; (*p)++; }
    }
    return 1;
}

static int ch_tz_footer(ch_tz_t *tz, const char *p) {
    int offset;
    if (!ch_tz_abbreviation(&p) || !ch_tz_seconds(&p, &offset)) return 0;
    tz->standard = -offset;
    tz->footer = 1;
    if (!*p) return 1;
    if (!ch_tz_abbreviation(&p)) return 0;
    tz->has_dst = 1;
    tz->daylight = tz->standard + 3600;
    if (*p != ',') {
        if (!ch_tz_seconds(&p, &offset)) return 0;
        tz->daylight = -offset;
    }
    if (*p++ != ',' || !ch_tz_parse_rule(&p, &tz->start)) return 0;
    if (*p++ != ',' || !ch_tz_parse_rule(&p, &tz->end)) return 0;
    return !*p;
}

static uint32_t ch_tz_u32(const unsigned char *p) {
    return (uint32_t)p[0] << 24 | (uint32_t)p[1] << 16
         | (uint32_t)p[2] << 8 | p[3];
}

static uint64_t ch_tz_section_size(const unsigned char *h, int width) {
    return (uint64_t)ch_tz_u32(h + 32) * (width + 1)
         + (uint64_t)ch_tz_u32(h + 36) * 6 + ch_tz_u32(h + 40)
         + (uint64_t)ch_tz_u32(h + 28) * (width + 4)
         + ch_tz_u32(h + 20) + ch_tz_u32(h + 24);
}

static void ch_tz_free(ch_tz_t *tz) {
    while (tz) {
        ch_tz_t *next = tz->next;
        Safefree(tz->name);
        Safefree(tz->transitions);
        Safefree(tz->indices);
        Safefree(tz);
        tz = next;
    }
}

static ch_tz_t *ch_tz_parse(const unsigned char *h, size_t length) {
    ch_tz_t *tz = NULL;
    const unsigned char *p;
    uint64_t size;
    uint32_t i;
    int width = 4;
    if (length < 44 || memcmp(h, "TZif", 4)) return NULL;
    size = ch_tz_section_size(h, width);
    if (size > length - 44) return NULL;
    if (h[4] == '2' || h[4] == '3') {
        h += 44 + (size_t)size;
        length -= 44 + (size_t)size;
        if (length < 44 || memcmp(h, "TZif", 4)) return NULL;
        width = 8;
        size = ch_tz_section_size(h, width);
        if (size > length - 44) return NULL;
    } else if (h[4] != 0) {
        return NULL;
    }
    Newxz(tz, 1, ch_tz_t);
    tz->count = ch_tz_u32(h + 32);
    tz->type_count = ch_tz_u32(h + 36);
    if (!tz->type_count || tz->type_count > 256) goto invalid;
    p = h + 44;
    if (tz->count) {
        Newx(tz->transitions, tz->count, int64_t);
        Newx(tz->indices, tz->count, unsigned char);
    }
    for (i = 0; i < tz->count; i++, p += width) {
        uint64_t v = ch_tz_u32(p);
        tz->transitions[i] = width == 8 ? (int64_t)((v << 32) | ch_tz_u32(p + 4))
                                       : (int64_t)(int32_t)v;
        if (i && tz->transitions[i] <= tz->transitions[i - 1]) goto invalid;
    }
    for (i = 0; i < tz->count; i++) {
        if (p[i] >= tz->type_count) goto invalid;
        tz->indices[i] = p[i];
    }
    p += tz->count;
    for (i = 0; i < tz->type_count; i++, p += 6) {
        tz->offsets[i] = (int32_t)ch_tz_u32(p);
        if (tz->offsets[i] < -604800 || tz->offsets[i] > 604800) goto invalid;
    }
    if (width == 8 && length > 44 + size) {
        size_t flen = length - 44 - (size_t)size;
        const char *f = (const char *)h + 44 + (size_t)size;
        if (flen < 2 || f[0] != '\n' || f[flen - 1] != '\n') goto invalid;
        if (flen > 2) {
            char *text;
            int ok;
            if (memchr(f + 1, 0, flen - 2)) goto invalid;
            Newx(text, flen - 1, char);
            Copy(f + 1, text, flen - 2, char);
            text[flen - 2] = '\0';
            ok = ch_tz_footer(tz, text);
            Safefree(text);
            if (!ok) goto invalid;
        }
    }
    return tz;
invalid:
    ch_tz_free(tz);
    return NULL;
}

/* The named zone from *zones, loading it on first use. NULL with a
 * message in err when it is unknown or unreadable. */
static ch_tz_t *ch_tz_load(ch_tz_t **zones, const char *name,
                           char *err, size_t errsz) {
    static const char *dirs[] = {
        "/usr/share/zoneinfo", "/usr/lib/zoneinfo", "/usr/share/lib/zoneinfo"
    };
    const char *tzdir = getenv("TZDIR");
    ch_tz_t *tz;
    FILE *fh = NULL;
    unsigned char *data = NULL;
    size_t len = 0, cap = 0;
    int d;
    for (tz = *zones; tz; tz = tz->next)
        if (!strcmp(tz->name, name)) return tz;
    if (!strcmp(name, "UTC") || !strcmp(name, "Etc/UTC") || !strcmp(name, "GMT")
        || !strcmp(name, "Etc/GMT") || !strcmp(name, "UCT")
        || !strcmp(name, "Universal") || !strcmp(name, "Zulu")) {
        Newxz(tz, 1, ch_tz_t);
        goto loaded;
    }
    if (!*name || *name == '/' || strstr(name, "..") || strchr(name, '\\')
        || strlen(name) > 200) {
        snprintf(err, errsz, "invalid timezone '%.200s'", name);
        return NULL;
    }
    for (d = 0; d < (tzdir ? 1 : 3) && !fh; d++) {
        char path[512];
        snprintf(path, sizeof(path), "%s/%s", tzdir ? tzdir : dirs[d], name);
        fh = fopen(path, "rb");
    }
    if (!fh) {
        snprintf(err, errsz, "unknown timezone '%s' or missing timezone "
                 "database", name);
        return NULL;
    }
    for (;;) {
        size_t n;
        if (len == cap) {
            if (cap >= 16777216) break;
            cap = cap ? cap * 2 : 8192;
            Renew(data, cap, unsigned char);
        }
        n = fread(data + len, 1, cap - len, fh);
        if (n == 0) break;
        len += n;
    }
    if (ferror(fh) || len >= 16777216) {
        fclose(fh);
        Safefree(data);
        snprintf(err, errsz, "cannot read timezone '%s'", name);
        return NULL;
    }
    fclose(fh);
    tz = data ? ch_tz_parse(data, len) : NULL;
    Safefree(data);
    if (!tz) {
        snprintf(err, errsz, "invalid TZif data for timezone '%s'", name);
        return NULL;
    }
loaded:
    {
        size_t n = strlen(name);
        Newx(tz->name, n + 1, char);
        Copy(name, tz->name, n + 1, char);
    }
    tz->next = *zones;
    *zones = tz;
    return tz;
}
