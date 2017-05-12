/*
 * Translated default messages for the jQuery validation plugin.
 * Language: CN
 * Author: Fayland Lam <fayland at gmail dot com>
 */
jQuery.extend(jQuery.validator.messages, {
        required: "必選字段",
		remote: "請修正該字段",
		email: "請輸入正確格式的電子郵件",
		url: "請輸入合法的網址",
		date: "請輸入合法的日期",
		dateISO: "請輸入合法的日期 (ISO).",
		number: "請輸入合法的數字",
		digits: "只能輸入整數",
		creditcard: "請輸入合法的信用卡號",
		equalTo: "請再次輸入相同的值",
		accept: "請輸入擁有合法後綴名的字符串",
		maxLength: jQuery.format("請輸入一個長度最多是 {0} 的字符串"),
		minLength: jQuery.format("請輸入一個長度最少是 {0} 的字符串"),
		rangeLength: jQuery.format("請輸入一個長度介于 {0} 和 {1} 之間的字符串"),
		rangeValue: jQuery.format("請輸入一個介于 {0} 和 {1} 之間的值"),
		maxValue: jQuery.format("請輸入一個最大為 {0} 的值"),
		minValue: jQuery.format("請輸入一個最小為 {0} 的值")
});