##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Status.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/04/05
## Modified 2022/04/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Status;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS
                 $CODES_LOCALE $CODES_LANG_SHORT );
    our $VERSION = 'v0.1.0';
    use constant 
    {
    HTTP_CONTINUE                           => 100,
    HTTP_SWITCHING_PROTOCOLS                => 101,
    HTTP_PROCESSING                         => 102,
    HTTP_EARLY_HINTS                        => 103,
    HTTP_OK                                 => 200,
    HTTP_CREATED                            => 201,
    HTTP_ACCEPTED                           => 202,
    HTTP_NON_AUTHORITATIVE                  => 203,
    HTTP_NO_CONTENT                         => 204,
    HTTP_RESET_CONTENT                      => 205,
    HTTP_PARTIAL_CONTENT                    => 206,
    HTTP_MULTI_STATUS                       => 207,
    HTTP_ALREADY_REPORTED                   => 208,
    HTTP_IM_USED                            => 226,
    HTTP_MULTIPLE_CHOICES                   => 300,
    HTTP_MOVED_PERMANENTLY                  => 301,
    HTTP_MOVED_TEMPORARILY                  => 302,
    HTTP_SEE_OTHER                          => 303,
    HTTP_NOT_MODIFIED                       => 304,
    HTTP_USE_PROXY                          => 305,
    HTTP_TEMPORARY_REDIRECT                 => 307,
    HTTP_PERMANENT_REDIRECT                 => 308,
    HTTP_BAD_REQUEST                        => 400,
    HTTP_UNAUTHORIZED                       => 401,
    HTTP_PAYMENT_REQUIRED                   => 402,
    HTTP_FORBIDDEN                          => 403,
    HTTP_NOT_FOUND                          => 404,
    HTTP_METHOD_NOT_ALLOWED                 => 405,
    HTTP_NOT_ACCEPTABLE                     => 406,
    HTTP_PROXY_AUTHENTICATION_REQUIRED      => 407,
    HTTP_REQUEST_TIME_OUT                   => 408,
    HTTP_CONFLICT                           => 409,
    HTTP_GONE                               => 410,
    HTTP_LENGTH_REQUIRED                    => 411,
    HTTP_PRECONDITION_FAILED                => 412,
    HTTP_REQUEST_ENTITY_TOO_LARGE           => 413,
    # Compatibility with HTTP::Status
    HTTP_PAYLOAD_TOO_LARGE                  => 413,
    HTTP_REQUEST_URI_TOO_LARGE              => 414,
    HTTP_URI_TOO_LONG                       => 414,
    HTTP_UNSUPPORTED_MEDIA_TYPE             => 415,
    HTTP_RANGE_NOT_SATISFIABLE              => 416,
    # Compatibility with HTTP::Status
    HTTP_REQUEST_RANGE_NOT_SATISFIABLE      => 416,
    HTTP_EXPECTATION_FAILED                 => 417,
    HTTP_I_AM_A_TEA_POT                     => 418,
    # Compatibility with HTTP::Status
    HTTP_I_AM_A_TEAPOT                      => 418,
    HTTP_MISDIRECTED_REQUEST                => 421,
    HTTP_UNPROCESSABLE_ENTITY               => 422,
    HTTP_LOCKED                             => 423,
    HTTP_FAILED_DEPENDENCY                  => 424,
    HTTP_TOO_EARLY                          => 425,
    # Compatibility with HTTP::Status
    HTTP_NO_CODE                            => 425,
    # Compatibility with HTTP::Status
    HTTP_UNORDERED_COLLECTION               => 425,
    HTTP_UPGRADE_REQUIRED                   => 426,
    HTTP_PRECONDITION_REQUIRED              => 428,
    HTTP_TOO_MANY_REQUESTS                  => 429,
    HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE    => 431,
    HTTP_CONNECTION_CLOSED_WITHOUT_RESPONSE => 444,
    HTTP_UNAVAILABLE_FOR_LEGAL_REASONS      => 451,
    HTTP_CLIENT_CLOSED_REQUEST              => 499,
    HTTP_INTERNAL_SERVER_ERROR              => 500,
    HTTP_NOT_IMPLEMENTED                    => 501,
    HTTP_BAD_GATEWAY                        => 502,
    HTTP_SERVICE_UNAVAILABLE                => 503,
    HTTP_GATEWAY_TIME_OUT                   => 504,
    HTTP_VERSION_NOT_SUPPORTED              => 505,
    HTTP_VARIANT_ALSO_VARIES                => 506,
    HTTP_INSUFFICIENT_STORAGE               => 507,
    HTTP_LOOP_DETECTED                      => 508,
    HTTP_BANDWIDTH_LIMIT_EXCEEDED           => 509,
    HTTP_NOT_EXTENDED                       => 510,
    HTTP_NETWORK_AUTHENTICATION_REQUIRED    => 511,
    HTTP_NETWORK_CONNECT_TIMEOUT_ERROR      => 599,
    };
    our @EXPORT_OK = qw(
        HTTP_ACCEPTED HTTP_ALREADY_REPORTED HTTP_BAD_GATEWAY HTTP_BAD_REQUEST
        HTTP_BANDWIDTH_LIMIT_EXCEEDED HTTP_CLIENT_CLOSED_REQUEST HTTP_CONFLICT
        HTTP_CONNECTION_CLOSED_WITHOUT_RESPONSE HTTP_CONTINUE HTTP_CREATED
        HTTP_EARLY_HINTS HTTP_EXPECTATION_FAILED HTTP_FAILED_DEPENDENCY
        HTTP_FORBIDDEN HTTP_GATEWAY_TIME_OUT HTTP_GONE HTTP_IM_USED
        HTTP_INSUFFICIENT_STORAGE HTTP_INTERNAL_SERVER_ERROR
        HTTP_I_AM_A_TEAPOT HTTP_I_AM_A_TEA_POT HTTP_LENGTH_REQUIRED
        HTTP_LOCKED HTTP_LOOP_DETECTED HTTP_METHOD_NOT_ALLOWED
        HTTP_MISDIRECTED_REQUEST HTTP_MOVED_PERMANENTLY HTTP_MOVED_TEMPORARILY
        HTTP_MULTIPLE_CHOICES HTTP_MULTI_STATUS
        HTTP_NETWORK_AUTHENTICATION_REQUIRED
        HTTP_NETWORK_CONNECT_TIMEOUT_ERROR HTTP_NON_AUTHORITATIVE
        HTTP_NOT_ACCEPTABLE HTTP_NOT_EXTENDED HTTP_NOT_FOUND
        HTTP_NOT_IMPLEMENTED HTTP_NOT_MODIFIED HTTP_NO_CODE HTTP_NO_CONTENT
        HTTP_OK HTTP_PARTIAL_CONTENT HTTP_PAYLOAD_TOO_LARGE
        HTTP_PAYMENT_REQUIRED HTTP_PERMANENT_REDIRECT HTTP_PRECONDITION_FAILED
        HTTP_PRECONDITION_REQUIRED HTTP_PROCESSING
        HTTP_PROXY_AUTHENTICATION_REQUIRED HTTP_RANGE_NOT_SATISFIABLE
        HTTP_REQUEST_ENTITY_TOO_LARGE HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE
        HTTP_REQUEST_RANGE_NOT_SATISFIABLE HTTP_REQUEST_TIME_OUT
        HTTP_REQUEST_URI_TOO_LARGE HTTP_RESET_CONTENT HTTP_SEE_OTHER
        HTTP_SERVICE_UNAVAILABLE HTTP_SWITCHING_PROTOCOLS
        HTTP_TEMPORARY_REDIRECT HTTP_TOO_EARLY HTTP_TOO_MANY_REQUESTS
        HTTP_UNAUTHORIZED HTTP_UNAVAILABLE_FOR_LEGAL_REASONS
        HTTP_UNORDERED_COLLECTION HTTP_UNPROCESSABLE_ENTITY
        HTTP_UNSUPPORTED_MEDIA_TYPE HTTP_UPGRADE_REQUIRED HTTP_URI_TOO_LONG
        HTTP_USE_PROXY HTTP_VARIANT_ALSO_VARIES HTTP_VERSION_NOT_SUPPORTED
    );
    our %EXPORT_TAGS = (
        all => [@EXPORT_OK], 
        common  => [qw( HTTP_NETWORK_AUTHENTICATION_REQUIRED HTTP_FORBIDDEN HTTP_NOT_FOUND HTTP_OK HTTP_TEMPORARY_REDIRECT HTTP_INTERNAL_SERVER_ERROR )],
    );
};

sub import
{
    my $class = shift( @_ );
    local $Exporter::ExportLevel = 1;
    Exporter::import( $class, @_ );
}

{
    use utf8;
    our $CODES_LOCALE =
    {
    # Ref: <https://developer.mozilla.org/de/docs/Web/HTTP/Status/100>
    # <https://www.dotcom-monitor.com/wiki/de/knowledge-base/http-status-codes/>
    'de_DE' =>
        {
        100 => "Weiter",
        101 => "Protokolle wechseln",
        102 => "Verarbeitung",
        103 => "Frühe Hinweise",
        200 => "OK",
        201 => "Erstellt",
        202 => "Akzeptiert",
        203 => "Nicht autorisierende Informationen",
        204 => "Kein Inhalt",
        205 => "Inhalt zurücksetzen",
        206 => "Teilinhalt",
        207 => "Multi-Status",
        208 => "Bereits gemeldet",
        226 => "IM verwendet",
        300 => "Mehrfachauswahlmöglichkeiten",
        301 => "Dauerhaft verschoben",
        302 => "Gefunden",
        303 => "Andere sehen",
        304 => "Nicht geändert",
        305 => "Proxy verwenden",
        307 => "Temporäre Weiterleitung",
        308 => "Permanente Weiterleitung",
        400 => "Schlechte Anfrage",
        401 => "Nicht autorisiert",
        402 => "Zahlung erforderlich",
        403 => "Verboten",
        404 => "Nicht gefunden",
        405 => "Methode nicht erlaubt",
        406 => "Nicht akzeptabel",
        407 => "Proxy-Authentifizierung erforderlich",
        408 => "Anfrage timeout",
        409 => "Konflikt",
        410 => "Gegangen",
        411 => "Länge erforderlich",
        412 => "Vorbedingung fehlgeschlagen",
        413 => "Nutzlast zu groß",
        414 => "Anfrage-URI zu lang",
        415 => "Nicht unterstützter Medientyp",
        416 => "Reichweite nicht erfüllbar",
        417 => "Erwartung fehlgeschlagen",
        418 => "Ich bin eine Teekanne",
        421 => "Fehlgeleitete Anfrage",
        422 => "Nicht verarbeitbare Entität",
        423 => "Gesperrt",
        424 => "Fehlgeschlagene Abhängigkeit",
        425 => "Zu früh",
        426 => "Upgrade erforderlich",
        428 => "Vorbedingung erforderlich",
        429 => "Zu viele Anfragen",
        431 => "Headerfelder zu groß anfordern",
        444 => "Verbindung ohne Antwort geschlossen",
        451 => "Aus rechtlichen Gründen nicht verfügbar",
        499 => "Client die Verbindung schließt",
        500 => "Interner Serverfehler",
        501 => "Nicht implementiert",
        502 => "Schlechtes Gateway",
        503 => "Dienst nicht verfügbar",
        504 => "Gateway-Zeitüberschreitung",
        505 => "HTTP-Version nicht unterstützt",
        506 => "Variante verhandelt auch",
        507 => "Unzureichende Lagerung",
        508 => "Schleife erkannt",
        509 => "Bandbreitenlimit überschritten",
        510 => "Nicht erweitert",
        511 => "Netzwerkauthentifizierung erforderlich",
        599 => "Timeout-Fehler bei Netzwerkverbindung",
        },
    'en_GB' => 
        {
        100 => "Continue",
        101 => "Switching Protocols",
        102 => "Processing",
        103 => "Early Hints",
        200 => "OK",
        201 => "Created",
        202 => "Accepted",
        203 => "Non-authoritative Information",
        204 => "No Content",
        205 => "Reset Content",
        206 => "Partial Content",
        207 => "Multi-Status",
        208 => "Already Reported",
        226 => "IM Used",
        300 => "Multiple Choices",
        301 => "Moved Permanently",
        302 => "Found",
        303 => "See Other",
        304 => "Not Modified",
        305 => "Use Proxy",
        307 => "Temporary Redirect",
        308 => "Permanent Redirect",
        400 => "Bad Request",
        401 => "Unauthorized",
        402 => "Payment Required",
        403 => "Forbidden",
        404 => "Not Found",
        405 => "Method Not Allowed",
        406 => "Not Acceptable",
        407 => "Proxy Authentication Required",
        408 => "Request Timeout",
        409 => "Conflict",
        410 => "Gone",
        411 => "Length Required",
        412 => "Precondition Failed",
        413 => "Payload Too Large",
        414 => "Request-URI Too Long",
        415 => "Unsupported Media Type",
        416 => "Requested Range Not Satisfiable",
        417 => "Expectation Failed",
        # Humour: April's fool
        # <https://en.wikipedia.org/wiki/Hyper_Text_Coffee_Pot_Control_Protocol>
        418 => "I'm a teapot",
        421 => "Misdirected Request",
        422 => "Unprocessable Entity",
        423 => "Locked",
        424 => "Failed Dependency",
        425 => "Too Early",
        426 => "Upgrade Required",
        428 => "Precondition Required",
        429 => "Too Many Requests",
        431 => "Request Header Fields Too Large",
        444 => "Connection Closed Without Response",
        451 => "Unavailable For Legal Reasons",
        499 => "Client Closed Request",
        500 => "Internal Server Error",
        501 => "Not Implemented",
        502 => "Bad Gateway",
        503 => "Service Unavailable",
        504 => "Gateway Timeout",
        505 => "HTTP Version Not Supported",
        506 => "Variant Also Negotiates",
        507 => "Insufficient Storage",
        508 => "Loop Detected",
        509 => "Bandwidth Limit Exceeded",
        510 => "Not Extended",
        511 => "Network Authentication Required",
        599 => "Network Connect Timeout Error",
        },
    'fr_FR' =>
        {
        100 => "Continuer",
        101 => "Changement de protocole",
        102 => "En traitement",
        103 => "Premiers indices",
        200 => "OK",
        201 => "Créé",
        202 => "Accepté",
        203 => "Information non certifiée",
        204 => "Pas de contenu",
        205 => "Contenu réinitialisé",
        206 => "Contenu partiel",
        207 => "Multi-Status",
        208 => "Déjà rapporté",
        226 => "IM Used",
        300 => "Choix multiples",
        301 => "Changement d'adresse définitif",
        302 => "Changement d'adresse temporaire",
        303 => "Voir ailleurs",
        304 => "Non modifié",
        305 => "Utiliser le proxy",
        307 => "Redirection temporaire",
        308 => "Redirection permanente",
        400 => "Mauvaise requête",
        401 => "Non autorisé",
        402 => "Paiement exigé",
        403 => "Interdit",
        404 => "Non trouvé",
        405 => "Méthode non autorisée",
        406 => "Pas acceptable",
        407 => "Authentification proxy exigée",
        408 => "Requête hors-délai",
        409 => "Conflit",
        410 => "Parti",
        411 => "Longueur exigée",
        412 => "Précondition échouée",
        413 => "Corps de requête trop grand",
        414 => "URI trop long",
        415 => "Format non supporté",
        416 => "Plage demandée invalide",
        417 => "Comportement erroné",
        # Humour; poisson d'avril
        # <https://fr.wikipedia.org/wiki/Hyper_Text_Coffee_Pot_Control_Protocol>
        418 => "Je suis une théière",
        421 => "Requête mal dirigée",
        422 => "Entité intraitable",
        423 => "Vérouillé",
        424 => "Dépendence échouée",
        425 => "Trop tôt",
        426 => "Mis-à-jour requise",
        428 => "Précondition requise",
        429 => "Trop de requête",
        431 => "Champs d'entête de la requête trop large",
        444 => "Connexion clôturée sans réponse",
        451 => "Indisponible pour des raisons légales",
        499 => "Le client a terminé la requête",
        500 => "Erreur interne du serveur",
        501 => "Non implémenté",
        502 => "Mauvais intermédiaire",
        503 => "Service indisponible",
        504 => "Intermédiaire hors-délai",
        505 => "Version HTTP non supportée",
        506 => "Variant Also Negotiates",
        507 => "Stoquage insuffisant",
        508 => "Boucle detectée",
        509 => "Limite de bande passante dépassée",
        510 => "Pas étendu",
        511 => "Autentification réseau requise",
        599 => "Erreur de timeout connexion réseau",
        },
    'ja_JP' =>
        {
        100 => "継続",
        101 => "プロトコル切替",
        102 => "処理中",
        103 => "早期のヒント",
        200 => "成功",
        201 => "作成完了",
        202 => "受理",
        203 => "信頼できない情報",
        204 => "内容なし",
        205 => "内容をリセット",
        206 => "部分的内容",
        207 => "複数のステータス",
        208 => "既に報告",
        226 => "IM使用",
        300 => "複数の選択",
        301 => "恒久的に移動した",
        302 => "発見した",
        303 => "他を参照せよ",
        304 => "未更新",
        305 => "プロキシを使用せよ",
        307 => "一時的リダイレクト",
        308 => "恒久的リダイレクト",
        400 => "リクエストが不正である",
        401 => "認証が必要である",
        402 => "支払いが必要である",
        403 => "禁止されている",
        404 => "未検出",
        405 => "許可されていないメソッド",
        406 => "受理できない",
        407 => "プロキシ認証が必要である",
        408 => "リクエストタイムアウト",
        409 => "競合",
        410 => "消滅した",
        411 => "長さが必要",
        412 => "前提条件で失敗した",
        413 => "ペイロードが大きすぎる",
        414 => "URIが大きすぎる",
        415 => "サポートしていないメディアタイプ",
        416 => "レンジは範囲外にある",
        417 => "Expectヘッダによる拡張が失敗",
        418 => "私はティーポット",
        421 => "誤ったリクエスト",
        422 => "処理できないエンティティ",
        423 => "ロックされている",
        424 => "依存関係で失敗",
        425 => "早期すぎ",
        426 => "アップグレード要求",
        428 => "条件付きリクエストを要求",
        429 => "リクエスト過大で拒否した",
        431 => "ヘッダサイズが過大",
        444 => "応答なしで接続が閉じられました",
        451 => "法的理由により利用不可",
        499 => "クライアントによるリクエストの終了",
        500 => "サーバ内部エラー",
        501 => "実装されていない",
        502 => "不正なゲートウェイ",
        503 => "サービス利用不可",
        504 => "ゲートウェイタイムアウト",
        505 => "サポートしていないHTTPバージョン",
        506 => "バリアントもコンテンツネゴシエーションを行う",
        507 => "容量不足",
        508 => "ループを検出",
        509 => "帯域幅制限超過",
        510 => "拡張できない",
        511 => "ネットワーク認証が必要",
        599 => "ネットワーク接続タイムアウトエラー",
        },
    # Ref: <https://developer.mozilla.org/ko/docs/Web/HTTP/Status>
    # <https://ko.wikipedia.org/wiki/HTTP_%EC%83%81%ED%83%9C_%EC%BD%94%EB%93%9C>
    # <http://wiki.hash.kr/index.php/HTTP>
    'ko_KR'=>
        {
        100 => "계속",
        101 => "스위칭 프로토콜",
        102 => "처리 중",
        103 => "사전로딩",
        200 => "확인",
        201 => "만든",
        202 => "수락",
        203 => "비 권한 정보",
        204 => "내용 없음",
        205 => "콘텐츠 재설정",
        206 => "부분적인 내용",
        207 => "다중 상태",
        208 => "이미보고",
        226 => "IM 사용",
        300 => "다중 선택",
        301 => "영구 이동",
        302 => "발견",
        303 => "다른 참조",
        304 => "수정되지 않음",
        305 => "프록시 사용",
        307 => "임시 리디렉션",
        308 => "영구 리디렉션",
        400 => "잘못된 요청",
        401 => "권한 없음",
        402 => "결제 필요",
        403 => "금지됨",
        404 => "찾을 수 없음",
        405 => "허용되지 않는 방법",
        406 => "허용되지 않음",
        407 => "프록시 인증 필요",
        408 => "요청 시간초과",
        409 => "충돌",
        410 => "사라짐",
        411 => "길이 필요",
        412 => "사전조건 실패",
        413 => "요청 속성이 너무 큼",
        414 => "요청 URI가 너무 긺",
        415 => "지원되지 않는 미디어 유형",
        416 => "처리할 수 없는 요청범위",
        417 => "예상 실패",
        418 => "나는 주전자입니다",
        421 => "잘못된 요청",
        422 => "처리할 수 없는 엔티티",
        423 => "잠김",
        424 => "실패된 의존성",
        425 => "너무일찍요청",
        426 => "업그레이드 필요",
        428 => "전제조건 필요",
        429 => "너무 많은 요청",
        431 => "요청 헤더 필드가 너무 큼",
        444 => "응답없이 연결이 닫힘",
        451 => "법적인 이유로 이용 불가",
        499 => "요청 헤더가 너무 큼",
        500 => "내부 서버 오류",
        501 => "구현되지 않음",
        502 => "불량 게이트웨이",
        503 => "서비스를 사용할 수 없음",
        504 => "게이트웨이 시간초과",
        505 => "HTTP 버전이 지원되지 않음",
        ## This is left in English by design
        506 => "Variant Also Negotiates",
        507 => "용량 부족",
        508 => "루프 감지됨",
        509 => "대역폭 제한 초과",
        510 => "확장되지 않음",
        511 => "네트워크 인증 필요",
        599 => "네트워크 연결 시간초과 오류",
        },
    # Ref: <https://ru.wikipedia.org/wiki/%D0%A1%D0%BF%D0%B8%D1%81%D0%BE%D0%BA_%D0%BA%D0%BE%D0%B4%D0%BE%D0%B2_%D1%81%D0%BE%D1%81%D1%82%D0%BE%D1%8F%D0%BD%D0%B8%D1%8F_HTTP>
    # <https://developer.roman.grinyov.name/blog/80>
    'ru_RU' => 
        {
        100 => "продолжай",
        101 => "переключение протоколов",
        102 => "идёт обработка",
        103 => "ранняя метаинформация",
        200 => "хорошо",
        201 => "создано",
        202 => "принято",
        203 => "информация не авторитетна",
        204 => "нет содержимого",
        205 => "сбросить содержимое",
        206 => "частичное содержимое",
        207 => "многостатусный",
        208 => "уже сообщалось",
        226 => "использовано IM",
        300 => "множество выборов",
        301 => "перемещено навсегда",
        302 => "найдено",
        303 => "смотреть другое",
        304 => "не изменялось",
        305 => "использовать прокси",
        307 => "временное перенаправление",
        308 => "постоянное перенаправление",
        400 => "неправильный запрос",
        401 => "не авторизован",
        402 => "необходима оплата",
        403 => "запрещено",
        404 => "не найдено",
        405 => "метод не поддерживается",
        406 => "неприемлемо",
        407 => "необходима аутентификация прокси",
        408 => "истекло время ожидания",
        409 => "конфликт",
        410 => "удалён",
        411 => "необходима длина",
        412 => "условие ложно",
        413 => "полезная нагрузка слишком велика",
        414 => "URI слишком длинный",
        415 => "неподдерживаемый тип данных",
        416 => "диапазон не достижим",
        417 => "ожидание не удалось",
        418 => "я — чайник",
        421 => "Неверно адресованный запрос",
        422 => "необрабатываемый экземпляр",
        423 => "заблокировано",
        424 => "невыполненная зависимость",
        425 => "слишком рано",
        426 => "необходимо обновление",
        428 => "необходимо предусловие",
        429 => "слишком много запросов",
        431 => "поля заголовка запроса слишком большие",
        444 => "Соединение закрыто без ответа",
        451 => "недоступно по юридическим причинам",
        499 => "клиент закрыл соединение",
        500 => "внутренняя ошибка сервера",
        501 => "не реализовано",
        502 => "ошибочный шлюз",
        503 => "сервис недоступен",
        504 => "шлюз не отвечает",
        505 => "версия HTTP не поддерживается",
        506 => "вариант тоже проводит согласование",
        507 => "переполнение хранилища",
        508 => "обнаружено бесконечное перенаправление",
        509 => "исчерпана пропускная ширина канала",
        510 => "не расширено",
        511 => "требуется сетевая аутентификация",
        599 => "Ошибка тайм-аута сетевого подключения",
        },
    # Ref: <https://zh.wikipedia.org/zh-tw/HTTP%E7%8A%B6%E6%80%81%E7%A0%81>
    # <https://developer.mozilla.org/zh-TW/docs/Web/HTTP/Status>
    # <https://www.websitehostingrating.com/zh-TW/http-status-codes-cheat-sheet/>
    'zh_TW' =>
        {
        100 => "繼續",
        101 => "交換協議",
        102 => "處理",
        103 => "早期提示",
        200 => "OK",
        201 => "已創建",
        202 => "已收到請求",
        203 => "非權威信息",
        204 => "沒有內容",
        205 => "重設內容",
        206 => "部分內容",
        207 => "種多狀態",
        208 => "已報告",
        226 => "使用了IM",
        300 => "種選擇",
        301 => "永久移動",
        302 => "找到了",
        303 => "查看其他",
        304 => "未修改",
        305 => "使用代理",
        307 => "臨時重定向",
        308 => "永久重定向",
        400 => "錯誤的請求",
        401 => "未經授權",
        402 => "需要付款",
        403 => "故宮",
        404 => "未找到",
        405 => "方法不允許",
        406 => "不可接受",
        407 => "要求代理身份驗證",
        408 => "請求超時",
        409 => "衝突",
        410 => "已經過時了",
        411 => "長度必需",
        412 => "前提條件失敗",
        413 => "有效負載過大",
        414 => "請求URI太長",
        415 => "不支持的媒體類型",
        416 => "請求的範圍不滿足",
        417 => "期望失敗",
        418 => "我是茶壺",
        421 => "錯誤的請求",
        422 => "無法處理的實體",
        423 => "已鎖定",
        424 => "依賴失敗",
        425 => "太早了",
        426 => "需要升級",
        428 => "需要先決條件",
        429 => "請求太多",
        431 => "請求標頭字段太大",
        444 => "連接關閉而沒有響應",
        451 => "由於法律原因不可用",
        499 => "個客戶關閉的請求",
        500 => "內部服務器錯誤",
        501 => "未實施",
        502 => "錯誤的網關",
        503 => "服務不可用",
        504 => "網關超時",
        505 => "不支持HTTP版本",
        506 => "變種還可以協商",
        507 => "存儲空間不足",
        508 => "檢測到環路",
        509 => "超過帶寬限制",
        510 => "未擴展",
        511 => "要求網絡身份驗證",
        599 => "網絡連接超時錯誤",
        },
    };
    our $CODES_LANG_SHORT =
    {
	de		=> 'de_DE',
	en		=> 'en_GB',
	fr		=> 'fr_FR',
	ja		=> 'ja_JP',
	ko      => 'ko_KR',
	ru      => 'ru_RU',
	zh		=> 'zh_TW',
    };
}

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub convert_short_lang_to_long
{
	my $self = shift( @_ );
	my $lang = shift( @_ );
	# Nothing to do; we already have a good value
	return( $lang ) if( $lang =~ /^[a-z]{2}_[A-Z]{2}$/ );
	return( $CODES_LANG_SHORT->{ lc( $lang ) } ) if( CORE::exists( $CODES_LANG_SHORT->{ lc( $lang ) } ) );
	return( '' );
}

sub is_cacheable_by_default
{
    my $self = shift( @_ );
    my $code = shift( @_ );
    return( $self->error( "A 3 digit code is required." ) ) if( !defined( $code ) || $code !~ /^\d{3}$/ );
    return(
           $code == 200 # OK
        || $code == 203 # Non-Authoritative Information
        || $code == 204 # No Content
        || $code == 206 # Not Acceptable
        || $code == 300 # Multiple Choices
        || $code == 301 # Moved Permanently
        || $code == 308 # Permanent Redirect
        || $code == 404 # Not Found
        || $code == 405 # Method Not Allowed
        || $code == 410 # Gone
        || $code == 414 # Request-URI Too Large
        || $code == 451 # Unavailable For Legal Reasons
        || $code == 501 # Not Implemented
    );
}

sub is_client_error { return( shift->_min_max( 400 => 500, @_ ) ); }

sub is_error { return( shift->_min_max( 400 => 600, @_ ) ); }

sub is_info { return( shift->_min_max( 100 => 200, @_ ) ); }

sub is_redirect { return( shift->_min_max( 300 => 400, @_ ) ); }

sub is_server_error { return( shift->_min_max( 500 => 600, @_ ) ); }

sub is_success { return( shift->_min_max( 200 => 300, @_ ) ); }

# Returns a status line for a given code
# e.g. status_message( 404 ) would yield "Not found"
# sub status_message { return( Apache2::RequestUtil::get_status_line( $_[1] ) ); }
sub status_message
{
    my $self = shift( @_ );
    my( $code, $lang );
    if( scalar( @_ ) == 2 )
    {
        ( $code, $lang ) = @_;
    }
    else
    {
        $code = shift( @_ );
        $lang = 'en_GB';
    }
    $lang = 'en_GB' if( !exists( $CODES_LOCALE->{ $lang } ) );
    my $ref = $CODES_LOCALE->{ $lang };
    return( $ref->{ $code } );
}

sub supported_languages
{
    my $self = shift( @_ );
    return( [sort( keys( %$CODES_LOCALE ) )] );
}

sub _min_max
{
    my $this = shift( @_ );
    my( $min, $max, $code ) = @_;
    return( $this->error( "A 3 digit code is required." ) ) if( !defined( $code ) || $code !~ /^\d{3}$/ );
    return( $code >= $min && $code < $max );
}

# NOTE: sub FREEZE is inherited

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: sub THAW is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Status - HTTP Status Codes & Locale Equivalents

=head1 SYNOPSIS

    use HTTP::Promise::Status ':common';
    use HTTP::Promise::Status ':all';
    say $HTTP::Promise::Status::HTTP_TOO_MANY_REQUESTS;
    # returns code 429

    say $HTTP::Promise::Status::CODES_LOCALE->{fr_FR}->{429} # Trop de requête
    # In Japanese: リクエスト過大で拒否した
    say $HTTP::Promise::Status::CODES_LOCALE->{ja_JP}->{429}

But maybe more simply:

    my $status = HTTP::Promise::Status->new;
    say $status->status_message( 429 => 'ja_JP' );
    # Or without the language code parameter, it will default to en_GB
    say $status->status_message( 429 );

    # Is success
    say $status->is_info( 102 ); # true
    say $status->is_success( 200 ); # true
    say $status->is_redirect( 302 ); # true
    say $status->is_error( 404 ); # true
    say $status->is_client_error( 403 ); # true
    say $status->is_server_error( 501 ); # true

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module allows the access of http constants similar to mod_perl and using their numeric value, and also allows to get the localised version of the http status for a given code for currently supported languages: fr_FR (French), en_GB (British English) and ja_JP (Japanese), de_DE (German), ko_KR (Korean), ru_RU (Russian), zh_TW (Taiwanese).

It also provides some functions to check if a given code is an information, success, redirect, error, client error or server error code.

=head1 METHODS

=head2 init

Creates an instance of L<HTTP::Promise::Status> and returns the object.

=head2 convert_short_lang_to_long

Given a 2 characters language code (not case sensitive) and this will return its iso 639 5 characters equivalent for supported languages.

For example:

    HTTP::Promise::Status->convert_short_lang_to_long( 'zh' );
    # returns: zh_TW

=head2 is_cacheable_by_default

Return true if the 3-digits code provided indicates that a response is cacheable by default, and it can be reused by a cache with heuristic expiration. All other status codes are not cacheable by default. See L<RFC 7231 - HTTP/1.1 Semantics and Content, Section 6.1. Overview of Status Codes|https://tools.ietf.org/html/rfc7231#section-6.1>.

=head2 is_client_error

Returns true if the 3-digits code provided is between 400 and 500

=head2 is_error

Returns true if the 3-digits code provided is between 400 and 600

=head2 is_info

Returns true if the 3-digits code provided is between 100 and 200

=head2 is_redirect

Returns true if the 3-digits code provided is between 300 and 400

=head2 is_server_error

Returns true if the 3-digits code provided is between 500 and 600

=head2 is_success

Returns true if the 3-digits code provided is between 200 and 300

=head2 status_message

Provided with a 3-digits http code and an optional language code such as C<en_GB> and this will return the status message in its localised form.

This is useful to provide response to error in the user preferred language. You can also use it to set a json response with the http error code along with a localised status message.

If no language code is provided, this will default to C<en_GB>.

See L</supported_languages> for the supported languages.

=head2 supported_languages

This will return a sorted array reference of support languages for status codes.

The following language codes are currently supported: de_DE (German), en_GB (British English), fr_FR (French), ja_JP (Japanese), ko_KR (Korean), ru_RU (Russian) and zh_TW (Traditional Chinese as spoken in Taiwan).

Feel free to contribute those codes in other languages.

=head1 CONSTANTS

The following constants can be exported. You can use the C<:all> tag to export them all, such as:

    use HTTP::Promise::Status qw( :all );

or you can use the tag C<:common> to export the following common status codes:

    HTTP_NETWORK_AUTHENTICATION_REQUIRED
    HTTP_FORBIDDEN
    HTTP_NOT_FOUND
    HTTP_OK
    HTTP_TEMPORARY_REDIRECT
    HTTP_INTERNAL_SERVER_ERROR

=head2 HTTP_CONTINUE (100)

See L<rfc 7231, section 5.1.1|https://tools.ietf.org/html/rfc7231#section-5.1.1> and section L<6.2.1|https://tools.ietf.org/html/rfc7231#section-6.2.1> and L<Mozilla docs|https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/100>

This is provisional response returned by the web server upon an abbreviated request to find out whether the web server will accept the actual request. For example when the client is sending a large file in chunks, such as in C<PUT> request (here a 742MB file):

    PUT /some//big/file.mp4 HTTP/1.1
    Host: www.example.org
    Content-Type: video/mp4
    Content-Length: 778043392
    Expect: 100-continue

If the server refused, it could return a C<413 Request Entity Too Large> or C<405 Method Not Allowed> or even C<401 Unauthorized>, or even a C<417 Expectation Failed> if it does not support this feature.

A response C<417 Expectation Failed> means the server is likely a HTTP/1.0 server or does not understand the request and the actual request must be sent, i.e. without the header field C<Expect: 100-continue>

In some REST API implementation, the server response code C<417> is used to mean the server understood the requested, but rejected it. This is a divergent use of the original purpose of this code.

=head2 HTTP_SWITCHING_PROTOCOLS (101)

See L<rfc7231, section 6.2.2|https://tools.ietf.org/html/rfc7231#section-6.2.2>

This is used to indicate that the TCP conncection is switching to a different protocol.

This is typically used for the L<WebSocket> protocol, which uses initially a HTTP handshake when establishing the connection. For example:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 13

Then the server could reply something like:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

=head2 HTTP_PROCESSING (102)

See L<rfc 2518 on WebDAV|https://tools.ietf.org/html/rfc2518>

This is returned to notify the client that the server is currently processing the request and that it is taking some time.

The server could return repeated instance of this response code until it is done processing the request and then send back the actual final response headers.

=head2 HTTP_EARLY_HINTS (103)

See L<rfc 8297 on Indicating Hints|https://tools.ietf.org/html/rfc8297>

This is a preemptive return code to notify the client to make some optimisations, while the actual final response headers are sent later. For example:

    HTTP/1.1 103 Early Hints
    Link: </style.css>; rel=preload; as=style
    Link: </script.js>; rel=preload; as=script

then, a few seconds, or minutes later:

    HTTP/1.1 200 OK
    Date: Mon, 16 Apr 2022 02:15:12 GMT
    Content-Length: 1234
    Content-Type: text/html; charset=utf-8
    Link: </style.css>; rel=preload; as=style
    Link: </script.js>; rel=preload; as=script

=head2 HTTP_OK (200)

See L<rfc7231, section 6.3.1|https://datatracker.ietf.org/doc/html/rfc7231#section-6.3.1>

This is returned to inform the request has succeeded. It can also alternatively be C<204 No Content> when there is no response body.

For example:

    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    Content-Length: 184
    Connection: keep-alive
    Cache-Control: s-maxage=300, public, max-age=0
    Content-Language: en-US
    Date: Mon, 18 Apr 2022 17:37:18 GMT
    ETag: "2e77ad1dc6ab0b53a2996dfd4653c1c3"
    Server: Apache/2.4
    Strict-Transport-Security: max-age=63072000
    X-Content-Type-Options: nosniff
    X-Frame-Options: DENY
    X-XSS-Protection: 1; mode=block
    Vary: Accept-Encoding,Cookie
    Age: 7

    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>A simple webpage</title>
    </head>
    <body>
      <h1>Simple HTML5 webpage</h1>
      <p>Hello, world!</p>
    </body>
    </html>

=head2 HTTP_CREATED (201)

See L<rfc7231, section 6.3.2|https://datatracker.ietf.org/doc/html/rfc7231#section-6.3.2>

This is returned to notify the related resource has been created, most likely by a C<PUT> request, such as:

    PUT /some/where HTTP/1.1
    Content-Type: text/html
    Host: example.org

Then, the server would reply:

    HTTP/1.1 201 Created
    ETag: "foo-bar"

=head2 HTTP_ACCEPTED (202)

See L<rfc7231, section 6.3.3|https://tools.ietf.org/html/rfc7231#section-6.3.3>

This is returned when the web server has accepted the request, without guarantee of successful completion.

Thus, the remote service would typically send an email to inform the user of the status, or maybe provide a link in the header. For example:

    POST /some/where HTTP/1.1
    Content-Type: application/json

Then the server response:

    HTTP/1.1 202 Accepted
    Link: </some/status/1234> rel="https://example.org/status"
    Content-Length: 0

=head2 HTTP_NON_AUTHORITATIVE (203)

See L<rfc 7231, section 6.3.4|https://tools.ietf.org/html/rfc7231#section-6.3.4>

This would typically be returned by an HTTP proxy after it has made some change to the content.

=head2 HTTP_NO_CONTENT (204)

L<See rfc 7231, section 6.3.5|https://tools.ietf.org/html/rfc7231#section-6.3.5>

This is returned when the request was processed successfully, but there is no body content returned.

=head2 HTTP_RESET_CONTENT (205)

L<See rfc 7231, section 6.3.6|https://tools.ietf.org/html/rfc7231#section-6.3.6>

This is to inform the client the request was successfully processed and the content should be reset, like a web form.

=head2 HTTP_PARTIAL_CONTENT (206)

See L<rfc 7233 on Range Requests|https://tools.ietf.org/html/rfc7233>

This is returned in response to a request for partial content, such as a certain number of bytes from a video. For example:

    GET /video.mp4 HTTP/1.1
    Range: bytes=1048576-2097152

Then, the server would reply something like:

    HTTP/1.1 206 Partial Content
    Content-Range: bytes 1048576-2097152/3145728
    Content-Type: video/mp4

=head2 HTTP_MULTI_STATUS (207)

See L<rfc 4918 on WebDAV|https://tools.ietf.org/html/rfc4918>

This is returned predominantly under the WebDav protocol, when multiple operations occurred. For example:

    HTTP/1.1 207 Multi-Status
    Content-Type: application/xml; charset="utf-8"
    Content-Length: 637

    <d:multistatus xmlns:d="DAV:">
        <d:response>
            <d:href>/calendars/johndoe/home/132456762153245.ics</d:href>
            <d:propstat>
                <d:prop>
                    <d:getetag>"xxxx-xxx"</d:getetag>
                </d:prop>
                <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
        </d:response>
        <d:response>
            <d:href>/calendars/johndoe/home/fancy-caldav-client-1234253678.ics</d:href>
            <d:propstat>
                <d:prop>
                    <d:getetag>"5-12"</d:getetag>
                </d:prop>
                <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
        </d:response>
    </d:multistatus>

=head2 HTTP_ALREADY_REPORTED (208)

See L<rfc 5842, section 7.1 on WebDAV bindings|https://tools.ietf.org/html/rfc5842#section-7.1>

This is returned predominantly under the WebDav protocol.

=head2 HTTP_IM_USED (226)

See L<rfc 3229 on Delta encoding|https://tools.ietf.org/html/rfc3229>

C<IM> stands for C<Instance Manipulation>.

This is an HTTP protocol extension used to indicate a diff performed and return only a fraction of the resource. This is especially true when the actual resource is large and it would be a waste of bandwidth to return the entire resource. For example:

    GET /foo.html HTTP/1.1
    Host: bar.example.net
    If-None-Match: "123xyz"
    A-IM: vcdiff, diffe, gzip

Then, the server would reply something like:

    HTTP/1.1 226 IM Used
    ETag: "489uhw"
    IM: vcdiff
    Date: Tue, 25 Nov 1997 18:30:05 GMT
    Cache-Control: no-store, im, max-age=30

See also the L<HTTP range request|https://tools.ietf.org/html/rfc7233> triggering a C<206 Partial Content> response.

=head2 HTTP_MULTIPLE_CHOICES (300)

See L<rfc 7231, section 6.4.1|https://tools.ietf.org/html/rfc7231#section-6.4.1> and L<rfc 5988|https://tools.ietf.org/html/rfc5988> for the C<Link> header.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/300>

This is returned when there is a redirection with multiple choices possible. For example:

    HTTP/1.1 300 Multiple Choices
    Server: Apache/2.4
    Access-Control-Allow-Headers: Content-Type,User-Agent
    Access-Control-Allow-Origin: *
    Link: </foo> rel="alternate"
    Link: </bar> rel="alternate"
    Content-Type: text/html
    Location: /foo

However, because there is no standard way to have the user choose, this response code is never used.

=head2 HTTP_MOVED_PERMANENTLY (301)

See L<rfc 7231, section 6.4.2|https://tools.ietf.org/html/rfc7231#section-6.4.2>

This is returned to indicate the target resource can now be found at a different location and all pointers should be updated accordingly. For example:

    HTTP/1.1 301 Moved Permanently
    Server: Apache/2.4
    Content-Type: text/html; charset=utf-8
    Date: Mon, 18 Apr 2022 17:33:08 GMT
    Location: https://example.org/some/where/else.html
    Keep-Alive: timeout=15, max=98
    Accept-Ranges: bytes
    Via: Moz-Cache-zlb05
    Connection: Keep-Alive
    Content-Length: 212

    <!DOCTYPE html>
    <html><head>
    <title>301 Moved Permanently</title>
    </head><body>
    <h1>Moved Permanently</h1>
    <p>The document has moved <a href="https://example.org/some/where/else.html">here</a>.</p>
    </body></html>

See also C<308 Permanent Redirect>

=head2 HTTP_MOVED_TEMPORARILY (302)

See L<rfc 7231, section 6.4.3|https://tools.ietf.org/html/rfc7231#section-6.4.3>

This is returned to indicate the resource was found, but somewhere else. This is to be understood as a temporary change.

The de facto standard, divergent from the original intent, is to point the client to a new location after a C<POST> request was performed. This is why the status code C<307> was created.

See also C<307 Temporary Redirect>, which more formally tells the client to reformulate their request to the new location.

See also C<303 See Other> for a formal implementation of aforementioned de facto standard, i.e. C<GET> new location after C<POST> request.

=head2 HTTP_SEE_OTHER (303)

See L<rfc 7231, section 6.4.4|https://tools.ietf.org/html/rfc7231#section-6.4.4>

This is returned to indicate the result of processing the request can be found at another location. For example, after a C<POST> request, such as:

    HTTP/1.1 303 See Other
    Server: Apache/2.4
    Location: /worked/well

It is considered better to redirect once request has been processed rather than returning the result immediately in the response body, because in the former case, this wil register a new entry in the client history whereas with the former, this would force the user to re-submit if the user did a back in history.

=head2 HTTP_NOT_MODIFIED (304)

See L<rfc 7232, section 4.1 on Conditional Request|https://tools.ietf.org/html/rfc7232#section-4.1>

This is returned in response to a conditional C<GET> or C<POST> request with headers such as:

=over 4

=item L<If-Match|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match>

=item L<If-None-Match|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match>

=item L<If-Modified-Since|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Modified-Since>

=item L<If-Unmodified-Since|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Unmodified-Since>

=item L<If-Range|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Range>

=back

For example:

    GET /foo HTTP/1.1
    Accept: text/html

Then, the server would reply something like:

    HTTP/1.1 200 Ok
    Content-Type: text/html
    ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"

Later, the client would do another request, such as:

    GET /foo HTTP/1.1
    Accept: text/html
    If-None-Match: "33a64df551425fcc55e4d42a148795d9f25f89d4"

And if nothing changed, the server would return something like this:

    HTTP/1.1 304 Not Modified
    ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"

=head2 HTTP_USE_PROXY (305)

See L<rfc 7231, section 6.4.5|https://tools.ietf.org/html/rfc7231#section-6.4.5> and the L<rfc 2616, section 10.3.6 deprecating this status code|https://tools.ietf.org/html/rfc2616#section-10.3.6>

This is returned to indicate to the client to submit the request again, using a proxy. For example:

    HTTP/1.1 305 Use Proxy
    Location: https://proxy.example.org:8080/

This is deprecated and is not in use.

=head2 306 Switch Proxy

This is deprecated and now a reserved status code that was L<originally designed|https://lists.w3.org/Archives/Public/ietf-http-wg-old/1997MayAug/0373.html> to indicate to the client the need to change proxy, but was deemed ultimately a security risk. See the original L<rfc draft|https://datatracker.ietf.org/doc/html/draft-cohen-http-305-306-responses-00>

For example:

    HTTP/1.1 306 Switch Proxy
    Set-Proxy: SET; proxyURI="https://proxy.example.org:8080/" scope="http://", seconds=100

=head2 HTTP_TEMPORARY_REDIRECT (307)

See L<rfc 2731, section 6.4.7|https://tools.ietf.org/html/rfc7231#section-6.4.7>

This is returned to indicate the client to perform the request again at a different location. The difference with status code C<302> is that the client would redirect to the new location using a C<GET> method, whereas with the status code C<307>, they have to perform the same request.

For example:

    HTTP/1.1 307 Temporary Redirect
    Server: Apache/2.4
    Location: https://example.org/some/where/else.html

=head2 HTTP_PERMANENT_REDIRECT (308)

See L<rfc 7538 on Permanent Redirect|https://tools.ietf.org/html/rfc7538>

Similar to the status code C<307> and C<302>, the status code C<308> indicates to the client to perform the request again at a different location and that the location has changed permanently. This echoes the status code C<301>, except that the standard with C<301> is for clients to redirect using C<GET> method even if originally the method used was C<POST>. With the status code C<308>, the client must reproduce the request with the original method.

For example:

    GET / HTTP/1.1
    Host: example.org

Then, the server would respond something like:

    HTTP/1.1 308 Permanent Redirect
    Server: Apache/2.4
    Content-Type: text/html; charset=UTF-8
    Location: https://example.org/some/where/else.html
    Content-Length: 393

    <!DOCTYPE HTML>
    <html>
       <head>
          <title>Permanent Redirect</title>
          <meta http-equiv="refresh"
                content="0; url=https://example.org/some/where/else.html">
       </head>
       <body>
          <p>
             The document has been moved to
             <a href="https://example.org/some/where/else.html"
             >https://example.org/some/where/else.html</a>.
          </p>
       </body>
    </html>

=head2 HTTP_BAD_REQUEST (400)

See L<rfc 7231, section 6.5.1|https://tools.ietf.org/html/rfc7231#section-6.5.1>

This is returned to indicate the client made a request the server could not interpret.

This is generally used as a fallback client-error code when other mode detailed C<4xx> code are not suitable.

=head2 HTTP_UNAUTHORIZED (401)

See L<rfc 7235, section 3.1 on Authentication|https://tools.ietf.org/html/rfc7235#section-3.1>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/401>

This is returned to indicate to the client it must authenticate first before issuing the request.

See also status code C<403 Forbidden> when client is outright forbidden from accessing the resource.

For example:

    HTTP/1.1 401 Unauthorized
    WWW-Authenticate: Basic; realm="Secured area"

or, for APIs:

    HTTP/1.1 401 Unauthorized
    WWW-Authenticate: Bearer

or, combining both:

    HTTP/1.1 401 Unauthorized
    WWW-Authenticate: Basic; realm="Dev zone", Bearer

which equates to:

    HTTP/1.1 401 Unauthorized
    WWW-Authenticate: Basic; realm="Dev zone"
    WWW-Authenticate: Bearer

So, for example, a user C<aladdin> with password C<opensesame> would result in the following request:

    GET / HTTP/1.1
    Authorization: Basic YWxhZGRpbjpvcGVuc2VzYW1l

See also L<Mozilla documentation on Authorization header|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization>

=head2 HTTP_PAYMENT_REQUIRED (402)

See L<rfc 7231, section 6.5.2|https://tools.ietf.org/html/rfc7231#section-6.5.2>

This was originally designed to inform the client that the resource could only be accessed once payment was made, but is now reserved and its current use is left at the discretion of the site implementing it.

=head2 HTTP_FORBIDDEN (403)

See L<rfc 7231, section 6.5.3|https://tools.ietf.org/html/rfc7231#section-6.5.3>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/403>

This is returned to indicate the client is barred from accessing the resource.

This is different from C<405 Method Not Allowed>, which is used when the client has proper permission to access the resource, but is using a method not allowed, such as using C<PUT> instead of C<GET> method.

=head2 HTTP_NOT_FOUND (404)

See L<rfc 7231, section 6.5.4|https://tools.ietf.org/html/rfc7231#section-6.5.4>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/404>

This is returned to indicate the resource does not exist anymore.

=head2 HTTP_METHOD_NOT_ALLOWED (405)

See L<rfc 7231, section 6.5.5|https://tools.ietf.org/html/rfc7231#section-6.5.5>

This is returned to indicate the client it used a L<method|https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods> not allowed, such as using C<PUT> instead of C<GET>. The server can point out the supported methods with the C<Allow> header, such as:

    HTTP/1.1 405 Method Not Allowed
    Content-Type: text/html
    Content-Length: 32
    Allow: GET, HEAD, OPTIONS, PUT

    <h1>405 Try another method!</h1>

=head2 HTTP_NOT_ACCEPTABLE (406)

See L<rfc 7231, section 6.5.6|https://tools.ietf.org/html/rfc7231#section-6.5.6>

This is returned to the client to indicate its requirements are not supported and thus not acceptable. This is in response to L<Accept|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept>, L<Accept-Charset|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Charset>, L<Accept-Encoding|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Encoding>, L<Accept-Language|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language> headers

For example:

    GET /foo HTTP/1.1
    Accept: application/json
    Accept-Language: fr-FR,en-GB;q=0.8,fr;q=0.6,en;q=0.4,ja;q=0.2

    HTTP/1.1 406 Not Acceptable
    Server: Apache/2.4
    Content-Type: text/html

    <h1>Je ne gère pas le type application/json</h1>


Then, the server would response something like:

=head2 HTTP_PROXY_AUTHENTICATION_REQUIRED (407)

See L<rfc 7235, section 3.2 on Authentication|https://tools.ietf.org/html/rfc7235#section-3.2>

This is returned to indicate the proxy used requires authentication. This is similar to the status code C<401 Unauthorized>.

=head2 HTTP_REQUEST_TIME_OUT (408)

See L<rfc 7231, section 6.5.7|https://tools.ietf.org/html/rfc7231#section-6.5.7>

This is returned to indicate the request took too long to be received and timed out. For example:

    HTTP/1.1 408 Request Timeout
    Connection: close
    Content-Type: text/plain
    Content-Length: 19

    Too slow! Try again

=head2 HTTP_CONFLICT (409)

See L<rfc 7231, section 6.5.8|https://tools.ietf.org/html/rfc7231#section-6.5.8>

This is returned to indicate a request conflict with the current state of the target resource, such as uploading with C<PUT> a file older than the remote one.

=head2 HTTP_GONE (410)

See L<rfc 7231, section 6.5.9|https://tools.ietf.org/html/rfc7231#section-6.5.9>

This is returned to indicate that the target resource is gone permanently. The subtle difference with the status code C<404> is that with C<404>, the resource may be only temporally unavailable whereas with C<410>, this is irremediable. For example:

    HTTP/1.1 410 Gone
    Server: Apache/2.4
    Content-Type: text/plain
    Content-Length: 30

    The resource has been removed.

=head2 HTTP_LENGTH_REQUIRED (411)

See L<rfc 7231, section 6.5.10|https://tools.ietf.org/html/rfc7231#section-6.5.10>

This is returned when the C<Content-Length> header was not provided by the client and the server requires it to be present. Most servers can do without.

=head2 HTTP_PRECONDITION_FAILED (412)

See L<rfc 7232 on Conditional Request|https://tools.ietf.org/html/rfc7232>

This is returned when some preconditions set by the client could not be met.

For example:

Issuing a C<PUT> request for a document if it does not already exist.

    PUT /foo/new-article.md HTTP/1.1
    Content-Type: text/markdown
    If-None-Match: *

Update a document if it has not changed since last time (etag)

    PUT /foo/old-article.md HTTP/1.1
    If-Match: "1345-12315"
    Content-Type: text/markdown

If those failed, it would return something like:

    HTTP/1.1 412 Precondition Failed
    Content-Type: text/plain
    Content-Length: 64

    The article you are tring to update has changed since last time.

If one adds the C<Prefer> header, the servers will return the current state of the resource, thus saving a round of request with a C<GET>, such as:

    PUT /foo/old-article.md HTTP/1.1
    If-Match: "1345-12315"
    Content-Type: text/markdown
    Prefer: return=representation

    ### Article version 2.1

Then, the server would respond something like:

    HTTP/1.1 412 Precondition Failed
    Content-Type: text/markdown
    Etag: "4444-12345"
    Vary: Prefer

    ### Article version 3.0

See also L<rfc 7240 about the Prefer header field|https://tools.ietf.org/html/rfc7240> and L<rfc 8144, Section 3.2|https://tools.ietf.org/html/rfc8144#section-3.2> about the usage of C<Prefer: return=representation> with status code C<412>

=head2 HTTP_REQUEST_ENTITY_TOO_LARGE (413)

See L<rfc 7231, section 6.5.11|https://tools.ietf.org/html/rfc7231#section-6.5.11>

This is returned when the body of the request is too large, such as when sending a file whose size has exceeded the maximum size limit.

For example:

    HTTP/1.1 413 Payload Too Large
    Retry-After: 3600
    Content-Type: text/html
    Content-Length: 52

    <p>You exceeded your quota. Try again in an hour</p>

See also L<rfc 7231, section 7.1.3|https://tools.ietf.org/html/rfc7231#section-7.1.3> on C<Retry-After> header field.

See also C<507 Insufficient Storage>

=head2 HTTP_PAYLOAD_TOO_LARGE (413)

Same as previous. Used here for compatibility with HTTP::Status

=head2 HTTP_REQUEST_URI_TOO_LARGE (414)

See L<rfc 7231, section 6.5.12|https://tools.ietf.org/html/rfc7231#section-6.5.12>

Although there is no official limit to the size of an URI, some servers may implement a limit and return this status code when the URI exceeds it. Usually, it is recommended not to exceed 2048 bytes for an URI.

=head2 HTTP_UNSUPPORTED_MEDIA_TYPE (415)

See L<rfc 7231, section 6.5.13|https://tools.ietf.org/html/rfc7231#section-6.5.13>

This is returned when the server received a request body type it does not understand.

This status code may be returned even if the C<Content-Type> header value is supported, because the server would still inspect the request body, such as with a broken C<JSON> payload.

Usually, in those cases, the server would rather return C<422 Unprocessable Entity>

=head2 HTTP_RANGE_NOT_SATISFIABLE (416)

See L<rfc 7233, section 4.4 on Range Requests|https://tools.ietf.org/html/rfc7233#section-4.4>

This is returned when the client made a range request it did not understand.

Client can issue range request instead of downloading the entire file, which is helpful for large data.

=head2 HTTP_REQUEST_RANGE_NOT_SATISFIABLE (416)

Same as previous. Used here for compatibility with HTTP::Status

=head2 HTTP_EXPECTATION_FAILED (417)

See L<rfc 7231, section 6.5.14|https://tools.ietf.org/html/rfc7231#section-6.5.14>

This is returned when the server received an C<Expect> header field value it did not understand.

For example:

    PUT /some//big/file.mp4 HTTP/1.1
    Host: www.example.org
    Content-Type: video/mp4
    Content-Length: 778043392
    Expect: 100-continue

Then, the server could respond with the following:

    HTTP/1.1 417 Expectation Failed
    Server: Apache/2.4
    Content-Type: text/plain
    Content-Length: 30

    We do not support 100-continue

See also L<rfc 7231, section 5.1.1|https://tools.ietf.org/html/rfc7231#section-5.1.1> on the C<Expect> header.

=head2 HTTP_I_AM_A_TEAPOT (418)

See L<rfc 2324 on HTCPC/1.0  1-april|https://tools.ietf.org/html/rfc2324>

This status code is not actually a real one, but one that was made by the IETF as an april-fools' joke, and it stuck. Attempts to remove it was met with L<strong resistance|https://save418.com/>.

There has even been L<libraries developed|https://github.com/dkundel/htcpcp-delonghi> to implement the L<HTCPC protocol|https://github.com/HyperTextCoffeePot/HyperTextCoffeePot>.

=head2 HTTP_I_AM_A_TEA_POT (418)

Same as previous.

=head2 HTTP_MISDIRECTED_REQUEST (421)

See L<rfc 7540, section 9.1.2 on HTTP/2|https://tools.ietf.org/html/rfc7540#section-9.1.2>

This is returned when the web server received a request that was not intended for him.

For example:

    GET /contact.html HTTP/1.1
    Host: foo.example.org

    HTTP/1.1 421 Misdirected Request
    Content-Type: text/plain
    Content-Length: 27

    This host unsupported here.

=head2 HTTP_UNPROCESSABLE_ENTITY (422)

See L<rfc 4918, section 11.2|https://tools.ietf.org/html/rfc4918#section-11.2>

This is returned when the web server understood the request, but deemed the body content to not be processable.

For example:

    POST /new-article HTTP/1.1
    Content-Type: application/json
    Content-Length: 26

    { "title": "Hello world!"}

Then, the web server could respond something like:

    HTTP/1.1 422 Unprocessable Entity
    Content-Type: application/problem+json
    Content-Length: 114

    {
      "type" : "https://example.org/errors/missing-property",
      "status": 422,
      "title": "Missing property: body"
    }

=head2 HTTP_LOCKED (423)

See L<rfc 4918 on WebDAV|https://tools.ietf.org/html/rfc4918>

This is returned under the WebDav protocol when one tries to make change to a locked resource.

=head2 HTTP_FAILED_DEPENDENCY (424)

See L<rfc 4918 on WebDAV|https://tools.ietf.org/html/rfc4918>

This is returned under the WebDav protocol when the processing of one of the resources failed.

=head2 HTTP_TOO_EARLY (425)

See L<rfc 8470, section 5.2 on Using Early Data in HTTP|https://tools.ietf.org/html/rfc8470#section-5.2>

This predominantly occurs during the TLS handshake to notify the client to retry a bit later once the TLS connection is up.

=head2 HTTP_NO_CODE (425)

Same as previous. Used here for compatibility with HTTP::Status

=head2 HTTP_UNORDERED_COLLECTION (425)

Same as previous. Used here for compatibility with HTTP::Status

=head2 HTTP_UPGRADE_REQUIRED (426)

See L<rfc 7231, section 6.5.15|https://tools.ietf.org/html/rfc7231#section-6.5.15>

This is returned to notify the client to use a newer version of the HTTP protocol.

=head2 HTTP_PRECONDITION_REQUIRED (428)

See L<rfc 6585, section 3 on Additional Codes|https://tools.ietf.org/html/rfc6585#section-3>

This is used when the web server requires the client to use condition requests, such as:

=over 4

=item L<If-Match|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match>

=item L<If-None-Match|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match>

=item L<If-Modified-Since|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Modified-Since>

=item L<If-Unmodified-Since|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Unmodified-Since>

=item L<If-Range|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Range>

=back

=head2 HTTP_TOO_MANY_REQUESTS (429)

See L<rfc 6585, section 4 on Additional Codes|https://tools.ietf.org/html/rfc6585#section-4>

This is returned when the server needs to notify the client to slow down the number of requests. This is predominantly used for API, but not only.

For example:

    HTTP/1.1 429 Too Many Requests
    Content-Type: text/plain
    Content-Length: 44
    Retry-After: 3600

    You exceeded the limit. Try again in an hour

=head2 HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE (431)

See L<rfc 6585, section 5 on Additional Codes|https://tools.ietf.org/html/rfc6585#section-5>

This is returned when the client issued a request containing HTTP header fields that are too big in size. Most likely culprit are the HTTP cookies.

=head2 HTTP_CONNECTION_CLOSED_WITHOUT_RESPONSE (444)

This is a non-standard status code used by some web servers, such as nginx, to instruct it to close the connection without sending a response back to the client, predominantly to deny malicious or malformed requests.

This status code is actually not seen by the client, but only appears in nginx log files.

=head2 HTTP_UNAVAILABLE_FOR_LEGAL_REASONS (451)

See L<rfc 7725 on Legal Obstacles|https://tools.ietf.org/html/rfc7725>

This is returned when, for some legal reasons, the resource could not be served.

This status code has been chosen on purpose, for its relation with the book L<Fahrenheit 451|https://en.wikipedia.org/wiki/Fahrenheit_451> from Ray Bradbury. In his book, the central theme is the censorship of literature. The book title itself "Fahrenheit 451" refers to the temperature at which paper ignites, i.e. 451 Fahrenheit or 232° Celsius.

For example:

    HTTP/1.1 451 Unavailable For Legal Reasons
    Link: <https://example.org/legal>; rel="blocked-by"
    Content-Type text/plain
    Content-Length: 48

    You are prohibited from accessing this resource.

=head2 HTTP_CLIENT_CLOSED_REQUEST (499)

This is a non-standard status code used by some web servers, such as nginx, when the client has closed the connection while the web server was still processing the request.

This status code is actually not seen by the client, but only appears in nginx log files.

=head2 HTTP_INTERNAL_SERVER_ERROR (500)

See L<rfc 7231, section 6.6.1|https://tools.ietf.org/html/rfc7231#section-6.6.1>

This is returned when an internal malfunction due to some bug of general processing error.

=head2 HTTP_NOT_IMPLEMENTED (501)

See L<rfc 7231, section 6.6.2|https://tools.ietf.org/html/rfc7231#section-6.6.2>

This is returned when the web server unexpectedly does not support certain features, although the request was itself acceptable.

=head2 HTTP_BAD_GATEWAY (502)

See L<rfc 7231, section 6.6.3|https://tools.ietf.org/html/rfc7231#section-6.6.3>

This is returned by proxy servers when the original target server is not operating properly and to notify the client of this.

=head2 HTTP_SERVICE_UNAVAILABLE (503)

See L<rfc 7231, section 6.6.4|https://tools.ietf.org/html/rfc7231#section-6.6.4>

This is returned when the web server is temporally incapable of processing the request, such as due to overload.

For example:

    HTTP/1.1 503 Service Unavailable
    Content-Type text/plain
    Content-Length: 56
    Retry-After: 1800

    System overload! Give us some time to increase capacity.

=head2 HTTP_GATEWAY_TIME_OUT (504)

See L<rfc 7231, section 6.6.5|https://tools.ietf.org/html/rfc7231#section-6.6.5>

This is returned by a proxy server when the upstream target server is not responding in a timely manner.

=head2 HTTP_VERSION_NOT_SUPPORTED (505)

See L<rfc 7231, section 6.6.6|https://tools.ietf.org/html/rfc7231#section-6.6.6>

This is returned when the web server does not support the HTTP version submitted by the client.

For example:

    GET / HTTP/4.0
    Host: www.example.org

Then, the server would respond something like:

    HTTP/1.1 505 HTTP Version Not Supported
    Server: Apache/2.4
    Date: Mon, 18 Apr 2022 15:23:35 GMT
    Content-Type: text/plain
    Content-Length: 30
    Connection: close

    505 HTTP Version Not Supported

=head2 HTTP_VARIANT_ALSO_VARIES (506)

See L<rfc 2295 on Transparant Ngttn|https://tools.ietf.org/html/rfc2295>

This is returned in the context of Transparent Content Negotiation when there is a server-side misconfiguration that leads the chosen variant itself to also engage in content negotiation, thus looping.

For example:

    GET / HTTP/1.1
    Host: www.example.org
    Accept: text/html; image/png; text/*; q=0.9
    Accept-Language: en-GB; en
    Accept-Charset: UTF-8
    Accept-Encoding: gzip, deflate, br

=head2 HTTP_INSUFFICIENT_STORAGE (507)

See L<rfc 4918, section 11.5 on WebDAV|https://tools.ietf.org/html/rfc4918#section-11.5>

This is returned in the context of WebDav protocol when a C<POST> or C<PUT> request leads to storing data, but the operations fails, because the resource is too large to fit on the remaining space on the server disk.

=head2 HTTP_LOOP_DETECTED (508)

See L<rfc 5842, section 7.2 on WebDAV bindings|https://tools.ietf.org/html/rfc5842#section-7.2>

This is returned in the context of WebDav when the target resource is looping.

=head2 HTTP_BANDWIDTH_LIMIT_EXCEEDED (509)

This is returned by some web servers when the amount of bandwidth consumed exceeded the maximum possible.

=head2 HTTP_NOT_EXTENDED (510)

See L<rfc 2774, section 6 on Extension Framework|https://tools.ietf.org/html/rfc2774#section-6>

This is returned by the web server who expected the client to use an extended http feature, but did not.

This is not widely implemented.

=head2 HTTP_NETWORK_AUTHENTICATION_REQUIRED (511)

See L<rfc 6585, section 6.1 on Additional Codes|https://tools.ietf.org/html/rfc6585#section-6.1>

This is returned by web server on private network to notify the client that a prior authentication is required to be able to browse the web. This is most likely used in location with private WiFi, such as lounges.

=head2 HTTP_NETWORK_CONNECT_TIMEOUT_ERROR (599)

This is returned by some proxy servers to signal a network connect timeout behind the proxy and the upstream target server.

This is not part of the standard.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head2 SEE ALSO

L<IANA HTTP codes list|http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml>, L<rfc7231|https://tools.ietf.org/html/rfc7231>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

