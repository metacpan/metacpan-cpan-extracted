package Lingua::GA::Gramadoir::Languages::vi;
# Vietnamese Translation for Gramadoir.
# Copyright © 2008 Kevin P. Scannell (msgid)
# Copyright © 2008 Free Software Foundation, Inc.
# This file is distributed under the same license as the gramadoir package.
# Clytie Siddall <clytie@riverland.net.au>, 2005-2008.
#
#msgid ""
#msgstr ""
#"Project-Id-Version: gramadoir 0.7\n"
#"Report-Msgid-Bugs-To: <kscanne@gmail.com>\n"
#"POT-Creation-Date: 2008-08-17 12:05-0500\n"
#"PO-Revision-Date: 2008-09-08 21:57+0930\n"
#"Last-Translator: Clytie Siddall <clytie@riverland.net.au>\n"
#"Language-Team: Vietnamese <vi-VN@googlegroups.com>\n"
#"MIME-Version: 1.0\n"
#"Content-Type: text/plain; charset=utf-8\n"
#"Content-Transfer-Encoding: 8bit\n"

use strict;
use warnings;
use utf8;
use base qw(Lingua::GA::Gramadoir::Languages);
use vars qw(%Lexicon);

%Lexicon = (
    "Line %d: [_1]\n"
 => "Dòng %d: [_1]\n",

    "unrecognized option [_1]"
 => "chưa chấp nhận tùy chọn [_1]",

    "option [_1] requires an argument"
 => "tùy chọn [_1] cần đến đối số",

    "option [_1] does not allow an argument"
 => "tùy chọn [_1] không cho phép đối số",

    "error parsing command-line options"
 => "gặp lỗi khi phân tách tùy chọn dòng lệnh",

    "Unable to set output color to [_1]"
 => "Không lập được màu dữ liệu xuất thành [_1]",

    "Language [_1] is not supported."
 => "Chưa hỗ trợ ngôn ngữ [_1].",

    "An Gramadoir"
 => "An Gramadóir",

    "Try [_1] for more information."
 => "Thử lệnh [_1] để tìm thấy thông tin thêm.",

    "version [_1]"
 => "phiên bản [_1]",

    "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law."
 => "Phần mềm này tự do; hãy xem mã nguồn để tìm thấy điều kiện sao chép.\nKhông bảo đảm gì cả, dù khả năng bán hay khả năng làm việc dứt khoát,\ntrong phạm vi mà luật cho phép.",

    "Usage: [_1] ~[OPTIONS~] ~[FILES~]"
 => "Cách sử dụng: [_1] ~[TÙY_CHỌN~] ~[TẬP_TIN~]",

    "Options for end-users:"
 => "Tùy chọn cho người sử dụng cuối:",

    "    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"
 => "    --iomlan       thông báo tất cả lỗi (thì không sử dụng ~/.neamhshuim)",

    "    --ionchod=ENC  specify the character encoding of the text to be checked"
 => "    --ionchod=MÃ  ghi rõ mã ký tự của văn bản để kiểm tra",

    "    --aschod=ENC   specify the character encoding for output"
 => "    --aschod=MÃ   ghi rõ mã ký tự cho dư liệu xuất",

    "    --comheadan=xx choose the language for error messages"
 => "    --comheadan=xx chọn ngôn ngữ cho thông điệp lỗi",

    "    --dath=COLOR   specify the color to use for highlighting errors"
 => "    --dath=MÀU   ghi rõ màu để nổi bật lỗi",

    "    --litriu       write misspelled words to standard output"
 => "    --litriu       ghi từ sai chính tả vào thiết bị xuất chuẩn",

    "    --aspell       suggest corrections for misspellings"
 => "    --aspell       đề nghị cách sửa từ sai chính tả",

    "    --aschur=FILE  write output to FILE"
 => "    --aschur=TẬP_TIN  ghi dữ liệu xuất TẬP TIN ấy",

    "    --help         display this help and exit"
 => "    --help         hiển thì _trợ giúp_ này rồi thoát",

    "    --version      output version information and exit"
 => "    --version      xuất thông tin _phiên bản_ rồi thoát",

    "Options for developers:"
 => "Tùy chọn cho lập trình viên:",

    "    --api          output a simple XML format for use with other applications"
 => "    --api          xuất khuôn dạng XML đơn giản để sử dụng với ứng dụng khác",

    "    --html         produce HTML output for viewing in a web browser"
 => "    --html         xuất bằng HTML để coi trong trình duyệt Mạng",

    "    --no-unigram   do not resolve ambiguous parts of speech by frequency"
 => "    --no-unigram   không giải quyết loại từ mơ hồ theo tần số",

    "    --xml          write tagged XML stream to standard output, for debugging"
 => "    --xml          ghi dòng XML có thẻ vào thiết bị xuất chuẩn để gỡ lỗi",

    "If no file is given, read from standard input."
 => "Nếu chưa chọn tập tin thì đọc dữ liệu nhập chuẩn.",

    "Send bug reports to <[_1]>."
 => "Hãy thông báo lỗi cho <[_1]>",

    "There is no such file."
 => "Không có tập tin như vậy.",

    "Is a directory"
 => "là thư mục",

    "Permission denied"
 => "Không cho phép",

    "[_1]: warning: problem closing [_2]\n"
 => "[_1]: cảnh báo: gặp khó đóng [_2]\n",

    "Currently checking [_1]"
 => "Hiện kiểm tra [_1]",

    "    --ilchiall     report unresolved ambiguities, sorted by frequency"
 => "    --ilchiall    thông báo các điều mơ hồ chưa giải quyết, sắp xếp theo tần số",

    "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)"
 => "    --minic        xuất tất cả thẻ, sắp xếp theo tần số (cho unigram-xx.txt)",

    "    --brill        find disambiguation rules via Brill's unsupervised algorithm"
 => "    --brill        tìm quy tắc chống mơ hồ thông qua thuật toán không có giám sát của Brill",

    "[_1]: problem reading the database\n"
 => "[_1]: gặp khó đọc cơ sở dữ liệu\n",

    "[_1]: `[_2]' corrupted at [_3]\n"
 => "[_1]: `[_2]' bị hỏng tại [_3]\n",

    "conversion from [_1] is not supported"
 => "chưa hỗ trợ dịch sang [_1]",

    "[_1]: illegal grammatical code\n"
 => "[_1]: không cho phép mã ngữ pháp ấy\n",

    "[_1]: no grammar codes: [_2]\n"
 => "[_1]: không có mã ngữ pháp: [_2]\n",

    "[_1]: unrecognized error macro: [_2]\n"
 => "[_1]: chưa chấp nhận macrô lỗi: [_2]\n",

    "Valid word but extremely rare in actual usage. Is this the word you want?"
 => "Từ đúng nhưng rất ít dụng: nên dùng từ này không?",

    "Repeated word"
 => "Một từ hai lần",

    "Unusual combination of words"
 => "Phối hợp từ một cách không thường",

    "The plural form is required here"
 => "Ở đây thì cần đến kiểu ở số nhiều",

    "The singular form is required here"
 => "Ở đây thì cần đến kiểu ở số ít",

    "Plural adjective required"
 => "Cần tính từ ở số nhiều",

    "Comparative adjective required"
 => "Cần đến tính từ so sánh",

    "Definite article required"
 => "Cần đến mạo từ hạn định",

    "Unnecessary use of the definite article"
 => "Không cần sử dụng mạo từ hạn định",

    "No need for the first definite article"
 => "Không cần mạo từ hạn định thứ nhất",

    "Unnecessary use of the genitive case"
 => "Không cần sử dụng cách sở hữu",

    "The genitive case is required here"
 => "Ở đây thì cần đến cách sở hữu",

    "You should use the present tense here"
 => "Ở đây thì nên dùng thời hiện tại",

    "It seems unlikely that you intended to use the subjunctive here"
 => "Ở đây bạn thật muốn sử dụng lối cầu khẩn?",

    "Usually used in the set phrase /[_1]/"
 => "Thường dụng trong cụm từ riêng ‘[_1]’",

    "You should use /[_1]/ here instead"
 => "Ở đây thì nên sử dụng ‘[_1]’ thay thế",

    "Non-standard form of /[_1]/"
 => "Hình thái không chuẩn của ‘[_1]’",

    "Derived from a non-standard form of /[_1]/"
 => "Gốc là hình thái không chuẩn của ‘[_1]’",

    "Derived incorrectly from the root /[_1]/"
 => "Gốc (không đúng) là ‘[_1]’",

    "Unknown word"
 => "Không biết từ",

    "Unknown word: /[_1]/?"
 => "Không biết từ: ‘[_1]’?",

    "Valid word but /[_1]/ is more common"
 => "Từ đúng nhưng /[_1]/ thường dùng hơn",

    "Not in database but apparently formed from the root /[_1]/"
 => "Không trong cơ sở dữ liệu nhưng hình như có gốc ‘[_1]’",

    "The word /[_1]/ is not needed"
 => "Không cần từ ‘[_1]’",

    "Do you mean /[_1]/?"
 => "Ý kiến bạn là ‘[_1]’ không?",

    "Derived form of common misspelling /[_1]/?"
 => "Hình thái bắt nguồn từ sai chính tả ‘[_1]’ không?",

    "Not in database but may be a compound /[_1]/?"
 => "Không trong cơ sở dữ liệu nhưng có lẽ là ‘[_1]’ ghép không?",

    "Not in database but may be a non-standard compound /[_1]/?"
 => "Không trong cơ sở dữ liệu nhưng có lẽ là ‘[_1]’ ghép không chuẩn không?",

    "Possibly a foreign word (the sequence /[_1]/ is highly improbable)"
 => "Có lẽ từ nước ngoài (dãy ‘[_1]’ rất không chắc)",

    "Gender disagreement"
 => "Giới tính không tương ứng",

    "Number disagreement"
 => "Số không tương ứng",

    "Case disagreement"
 => "Chữ hoa/thường không tương ứng",

    "Prefix /h/ missing"
 => "Thiếu tiền tố /h/",

    "Prefix /t/ missing"
 => "Thiếu tiền tố /t/",

    "Prefix /d'/ missing"
 => "Thiếu tiền tố /d'/",

    "Unnecessary prefix /h/"
 => "Không cần tiền tố /h/",

    "Unnecessary prefix /t/"
 => "Không cần tiền tố /t/",

    "Unnecessary prefix /d'/"
 => "Không cần tiền tố /d'/",

    "Unnecessary prefix /b'/"
 => "Không cần tiền tố /b'/",

    "Unnecessary initial mutation"
 => "Không cần đổi phụ âm đầu",

    "Initial mutation missing"
 => "Thiếu cách đổi phụ âm đầu",

    "Unnecessary lenition"
 => "Không cần thêm chữ h để làm cho phụ âm đầu mềm hơn",

    "The second lenition is unnecessary"
 => "Không cần sự nhược hoá thứ hai",

    "Often the preposition /[_1]/ causes lenition, but this case is unclear"
 => "Thường giới từ ‘[_1]’ gây ra thêm chữ h để là m cho phụ âm đầu mềm hơn, nhưng trường hợp này không rõ lắm",

    "Lenition missing"
 => "Thiếu cách thêm chữ h để làm cho phụ âm đầu mềm hơn",

    "Unnecessary eclipsis"
 => "Không cần che phụ âm đầu",

    "Eclipsis missing"
 => "Thiếu cách che phụ âm đầu",

    "The dative is used only in special phrases"
 => "Chỉ sử dụng tặng cách trong cụm từ đặc biệt",

    "The dependent form of the verb is required here"
 => "Ở đây thì cần đến kiểu động từ phụ thuộc,",

    "Unnecessary use of the dependent form of the verb"
 => "Không cần sử dụng kiểu động tư phụ thuộc",

    "The synthetic (combined) form, ending in /[_1]/, is often used here"
 => "Ở đây thì thường sử dụng kiểu tổng hợp (kết hợp) mà cuối cùng với ‘[_1]’",

    "Second (soft) mutation missing"
 => "Thiếu cách đổi phụ âm đầu thứ hai (mềm)",

    "Third (breathed) mutation missing"
 => "Thiếu cách đổi phụ âm đầu thứ ba (thở)",

    "Fourth (hard) mutation missing"
 => "Thiếu cách đổi phụ âm đầu thứ tư (cứng)",

    "Fifth (mixed) mutation missing"
 => "Thiếu cách đổi phụ âm đầu thứ năm (phối)",

    "Fifth (mixed) mutation after 'th missing"
 => "Thiếu cách đổi phụ âm đầu (phối) sau 'th",

    "Aspirate mutation missing"
 => "Thiếu sự biến đổi nguyên âm bật hơi",

    "This word violates the rules of Igbo vowel harmony"
 => "Từ này vi phạm quy tắc về hoà âm của âm Igbo",

);
1;
